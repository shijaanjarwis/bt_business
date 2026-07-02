import 'package:sqflite/sqflite.dart' hide DatabaseException;

import '../../../../core/accounting/account_types.dart';
import '../../../../core/accounting/payment_modes.dart';
import '../../../../core/accounting/transaction_types.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/gst_calculator.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../core/reminders/reminder_service.dart';
import '../../../../data/local/database/tables/accounting_tables.dart';
import '../../domain/entities/purchase_invoice.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../models/purchase_invoice_model.dart';

/// Persists purchase invoices with double-entry accounting and stock updates.
final class PurchasePostingService {
  const PurchasePostingService(this._db);

  final Database _db;

  Future<PurchaseInvoice> save({
    required String businessId,
    required SavePurchaseInput input,
  }) async {
    final computedLines = _computeLines(input);
    final totals = GstCalculator.aggregate(computedLines.map((line) => line.amounts).toList());

    if (totals.grandTotal <= 0) {
      throw const ValidationException('Invoice total must be greater than zero');
    }

    final paidAmount = (input.paidAmount ?? totals.grandTotal)
        .clamp(0, totals.grandTotal)
        .toDouble();
    if (paidAmount < 0) {
      throw const ValidationException('Paid amount cannot be negative');
    }

    final dueAmount = totals.grandTotal - paidAmount;
    final reminderDate = ReminderService.effectiveReminderDate(
      transactionType: TransactionTypes.purchase,
      dueAmount: dueAmount,
      requestedReminderDate: input.reminderDate,
    );

    await _validateItems(input.lines);

    final transactionId = input.id ?? IdGenerator.newId();
    final now = DateTime.now();

    await _db.transaction((txn) async {
      if (input.id != null) {
        await _revert(txn, input.id!);
      }

      final invoiceNo = input.invoiceNo ?? await _nextInvoiceNo(txn, businessId);
      final isoDate = DateFormatter.isoDate(input.date);

      await txn.insert(TransactionsTable.tableName, {
        TransactionsTable.id: transactionId,
        TransactionsTable.businessId: businessId,
        TransactionsTable.type: TransactionTypes.purchase,
        TransactionsTable.date: isoDate,
        TransactionsTable.partyId: input.partyId,
        TransactionsTable.invoiceNo: invoiceNo,
        TransactionsTable.notes: input.notes?.trim(),
        TransactionsTable.totalAmount: totals.grandTotal,
        TransactionsTable.paidAmount: paidAmount,
        TransactionsTable.dueAmount: dueAmount,
        TransactionsTable.reminderDate: ReminderService.reminderDateIso(reminderDate),
        TransactionsTable.paymentMode: input.paymentMode.code,
        TransactionsTable.gstType: input.gstType.code,
        TransactionsTable.subtotal: totals.subtotal,
        TransactionsTable.discountTotal: totals.discountTotal,
        TransactionsTable.taxableTotal: totals.taxableTotal,
        TransactionsTable.cgstTotal: totals.cgstTotal,
        TransactionsTable.sgstTotal: totals.sgstTotal,
        TransactionsTable.igstTotal: totals.igstTotal,
        TransactionsTable.createdAt: (input.existingCreatedAt ?? now).toIso8601String(),
        TransactionsTable.updatedAt: now.toIso8601String(),
      });

      for (var i = 0; i < computedLines.length; i++) {
        final line = computedLines[i];
        await txn.insert(TransactionLinesTable.tableName, {
          TransactionLinesTable.id: IdGenerator.newId(),
          TransactionLinesTable.transactionId: transactionId,
          TransactionLinesTable.itemId: line.input.itemId,
          TransactionLinesTable.itemName: line.input.itemName,
          TransactionLinesTable.hsnSac: line.input.hsnSac,
          TransactionLinesTable.qty: line.input.qty,
          TransactionLinesTable.rate: line.input.rate,
          TransactionLinesTable.discountAmount: line.amounts.discountAmount,
          TransactionLinesTable.gstRate: line.input.gstRate,
          TransactionLinesTable.taxableAmount: line.amounts.taxableAmount,
          TransactionLinesTable.cgstAmount: line.amounts.cgstAmount,
          TransactionLinesTable.sgstAmount: line.amounts.sgstAmount,
          TransactionLinesTable.igstAmount: line.amounts.igstAmount,
          TransactionLinesTable.lineTotal: line.amounts.lineTotal,
          TransactionLinesTable.sortOrder: i,
        });

        await txn.insert(StockMovementsTable.tableName, {
          StockMovementsTable.id: IdGenerator.newId(),
          StockMovementsTable.itemId: line.input.itemId,
          StockMovementsTable.transactionId: transactionId,
          StockMovementsTable.qtyDelta: line.input.qty,
          StockMovementsTable.rate: line.input.rate,
          StockMovementsTable.movementDate: isoDate,
        });

        await txn.rawUpdate(
          '''
          UPDATE ${ItemsTable.tableName}
          SET ${ItemsTable.qtyOnHand} = ${ItemsTable.qtyOnHand} + ?,
              ${ItemsTable.purchaseRate} = ?,
              ${ItemsTable.updatedAt} = ?
          WHERE ${ItemsTable.id} = ?
          ''',
          [line.input.qty, line.input.rate, now.toIso8601String(), line.input.itemId],
        );
      }

      await _postJournal(
        txn,
        businessId: businessId,
        transactionId: transactionId,
        input: input,
        totals: totals,
      );
    });

    final saved = await _fetchInvoice(transactionId);
    if (saved == null) {
      throw const DatabaseException('Failed to load saved purchase invoice');
    }
    return saved;
  }

  Future<void> delete(String transactionId) async {
    await _db.transaction((txn) async {
      await _revert(txn, transactionId);
    });
  }

  Future<void> _revert(Transaction txn, String transactionId) async {
    final rows = await txn.query(
      TransactionsTable.tableName,
      where: '${TransactionsTable.id} = ?',
      whereArgs: [transactionId],
      limit: 1,
    );
    if (rows.isEmpty) return;

    final transaction = rows.first;
    final paymentMode = PaymentMode.fromCode(
      transaction[TransactionsTable.paymentMode]! as String? ?? PaymentMode.cash.code,
    );
    final partyId = transaction[TransactionsTable.partyId] as String?;
    final grandTotal = (transaction[TransactionsTable.totalAmount] as num?)?.toDouble() ?? 0;

    final movements = await txn.query(
      StockMovementsTable.tableName,
      where: '${StockMovementsTable.transactionId} = ?',
      whereArgs: [transactionId],
    );
    final now = DateTime.now().toIso8601String();
    for (final movement in movements) {
      final itemId = movement[StockMovementsTable.itemId]! as String;
      final qtyDelta = (movement[StockMovementsTable.qtyDelta] as num).toDouble();
      await txn.rawUpdate(
        '''
        UPDATE ${ItemsTable.tableName}
        SET ${ItemsTable.qtyOnHand} = ${ItemsTable.qtyOnHand} - ?,
            ${ItemsTable.updatedAt} = ?
        WHERE ${ItemsTable.id} = ?
        ''',
        [qtyDelta, now, itemId],
      );
    }

    if (paymentMode == PaymentMode.credit && partyId != null) {
      await txn.rawUpdate(
        '''
        UPDATE ${PartiesTable.tableName}
        SET ${PartiesTable.balance} = ${PartiesTable.balance} + ?,
            ${PartiesTable.updatedAt} = ?
        WHERE ${PartiesTable.id} = ?
        ''',
        [grandTotal, now, partyId],
      );
    }

    await txn.delete(
      StockMovementsTable.tableName,
      where: '${StockMovementsTable.transactionId} = ?',
      whereArgs: [transactionId],
    );
    await txn.delete(
      JournalLinesTable.tableName,
      where: '${JournalLinesTable.transactionId} = ?',
      whereArgs: [transactionId],
    );
    await txn.delete(
      TransactionLinesTable.tableName,
      where: '${TransactionLinesTable.transactionId} = ?',
      whereArgs: [transactionId],
    );
    await txn.delete(
      TransactionsTable.tableName,
      where: '${TransactionsTable.id} = ?',
      whereArgs: [transactionId],
    );
  }

  Future<void> _postJournal(
    Transaction txn, {
    required String businessId,
    required String transactionId,
    required SavePurchaseInput input,
    required ({
      double subtotal,
      double discountTotal,
      double taxableTotal,
      double cgstTotal,
      double sgstTotal,
      double igstTotal,
      double grandTotal,
    }) totals,
  }) async {
    final cashAccountId = await _accountId(txn, businessId, AccountTypes.cash);
    final payableAccountId = await _accountId(txn, businessId, AccountTypes.payable);
    final stockAccountId = await _accountId(txn, businessId, AccountTypes.stock);
    final cgstAccountId = await _accountId(txn, businessId, AccountTypes.cgstPayable);
    final sgstAccountId = await _accountId(txn, businessId, AccountTypes.sgstPayable);
    final igstAccountId = await _accountId(txn, businessId, AccountTypes.igstPayable);

    await _insertLine(txn, transactionId, stockAccountId, debit: totals.taxableTotal);

    if (totals.cgstTotal > 0) {
      await _insertLine(txn, transactionId, cgstAccountId, debit: totals.cgstTotal);
    }
    if (totals.sgstTotal > 0) {
      await _insertLine(txn, transactionId, sgstAccountId, debit: totals.sgstTotal);
    }
    if (totals.igstTotal > 0) {
      await _insertLine(txn, transactionId, igstAccountId, debit: totals.igstTotal);
    }

    if (input.paymentMode == PaymentMode.cash) {
      await _insertLine(txn, transactionId, cashAccountId, credit: totals.grandTotal);
    } else {
      await _insertLine(
        txn,
        transactionId,
        payableAccountId,
        partyId: input.partyId,
        credit: totals.grandTotal,
      );
      await txn.rawUpdate(
        '''
        UPDATE ${PartiesTable.tableName}
        SET ${PartiesTable.balance} = ${PartiesTable.balance} - ?,
            ${PartiesTable.updatedAt} = ?
        WHERE ${PartiesTable.id} = ?
        ''',
        [totals.grandTotal, DateTime.now().toIso8601String(), input.partyId],
      );
    }
  }

  List<({PurchaseLineInput input, SaleLineAmounts amounts})> _computeLines(
    SavePurchaseInput input,
  ) {
    return input.lines.map((line) {
      final amounts = GstCalculator.computeLine(
        qty: line.qty,
        rate: line.rate,
        discountAmount: line.discountAmount,
        gstRate: line.gstRate,
        gstType: input.gstType,
      );
      return (input: line, amounts: amounts);
    }).toList();
  }

  Future<void> _validateItems(List<PurchaseLineInput> lines) async {
    for (final line in lines) {
      final rows = await _db.query(
        ItemsTable.tableName,
        where: '${ItemsTable.id} = ?',
        whereArgs: [line.itemId],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw ValidationException('Item not found: ${line.itemName}');
      }
    }
  }

  Future<String> _nextInvoiceNo(Transaction txn, String businessId) async {
    final rows = await txn.rawQuery(
      '''
      SELECT ${TransactionsTable.invoiceNo}
      FROM ${TransactionsTable.tableName}
      WHERE ${TransactionsTable.businessId} = ?
        AND ${TransactionsTable.type} = ?
        AND ${TransactionsTable.invoiceNo} LIKE 'PUR-%'
      ORDER BY ${TransactionsTable.createdAt} DESC
      LIMIT 1
      ''',
      [businessId, TransactionTypes.purchase],
    );

    var sequence = 1;
    if (rows.isNotEmpty && rows.first[TransactionsTable.invoiceNo] != null) {
      final last = rows.first[TransactionsTable.invoiceNo]! as String;
      final parts = last.split('-');
      if (parts.length == 2) {
        sequence = (int.tryParse(parts.last) ?? 0) + 1;
      }
    }
    return 'PUR-${sequence.toString().padLeft(4, '0')}';
  }

  Future<PurchaseInvoice?> _fetchInvoice(String transactionId) async {
    final rows = await _db.rawQuery(
      '''
      SELECT t.*, p.${PartiesTable.name} AS party_name
      FROM ${TransactionsTable.tableName} t
      INNER JOIN ${PartiesTable.tableName} p ON t.${TransactionsTable.partyId} = p.${PartiesTable.id}
      WHERE t.${TransactionsTable.id} = ?
      ''',
      [transactionId],
    );
    if (rows.isEmpty) return null;

    final lineRows = await _db.query(
      TransactionLinesTable.tableName,
      where: '${TransactionLinesTable.transactionId} = ?',
      whereArgs: [transactionId],
      orderBy: '${TransactionLinesTable.sortOrder} ASC',
    );
    final lines = lineRows.map(PurchaseInvoiceModel.lineFromMap).toList();
    return PurchaseInvoiceModel.fromJoinedMap(rows.first, lines: lines).invoice;
  }

  Future<void> _insertLine(
    Transaction txn,
    String transactionId,
    String accountId, {
    String? partyId,
    double debit = 0,
    double credit = 0,
  }) async {
    await txn.insert(JournalLinesTable.tableName, {
      JournalLinesTable.id: IdGenerator.newId(),
      JournalLinesTable.transactionId: transactionId,
      JournalLinesTable.accountId: accountId,
      JournalLinesTable.partyId: partyId,
      JournalLinesTable.debit: debit,
      JournalLinesTable.credit: credit,
    });
  }

  Future<String> _accountId(Transaction txn, String businessId, String type) async {
    final rows = await txn.query(
      AccountsTable.tableName,
      columns: [AccountsTable.id],
      where: '${AccountsTable.businessId} = ? AND ${AccountsTable.type} = ?',
      whereArgs: [businessId, type],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw StateError('Missing $type account for business $businessId');
    }
    return rows.first[AccountsTable.id]! as String;
  }
}
