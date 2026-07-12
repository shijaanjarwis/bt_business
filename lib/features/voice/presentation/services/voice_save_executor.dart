import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/accounting/gst_types.dart';
import '../../../../core/accounting/payment_breakdown.dart';
import '../../../../core/accounting/payment_modes.dart';
import '../../../../core/constants/item_units.dart';
import '../../../../core/di/data_revision.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../items/domain/repositories/item_repository.dart';
import '../../../items/presentation/providers/item_providers.dart';
import '../../../ledger/domain/entities/opening_balance_direction.dart';
import '../../../ledger/domain/entities/party_type.dart';
import '../../../ledger/domain/repositories/party_repository.dart';
import '../../../ledger/presentation/providers/party_providers.dart';
import '../../../payments/domain/repositories/expense_repository.dart';
import '../../../payments/presentation/providers/payment_providers.dart';
import '../../../purchase/domain/entities/purchase_invoice.dart';
import '../../../purchase/domain/repositories/purchase_repository.dart';
import '../../../purchase/presentation/providers/purchase_providers.dart';
import '../../../sales/domain/entities/sale_entry.dart';
import '../../../sales/domain/repositories/sale_repository.dart';
import '../../../sales/presentation/providers/sale_providers.dart';
import '../../domain/voice_draft.dart';
import '../../domain/voice_intent_type.dart';

/// Persists a confirmed voice preview using existing save use cases.
final class VoiceSaveExecutor {
  VoiceSaveExecutor({required WidgetRef ref}) : _ref = ref;

  final WidgetRef _ref;

  Future<Result<void>> save({
    required VoiceDraft draft,
    String? partyId,
    String? itemId,
    bool createParty = false,
    bool createItem = false,
  }) async {
    try {
      if (createParty && draft.partyName != null) {
        final created = await _createParty(draft.partyName!);
        if (created.isFailure) return Error(created.failureOrNull!);
        partyId = created.valueOrNull!.id;
      }

      if (createItem && draft.itemName != null) {
        final created = await _createItem(
          name: draft.itemName!,
          unit: draft.unit ?? ItemUnits.defaultUnit,
        );
        if (created.isFailure) return Error(created.failureOrNull!);
        itemId = created.valueOrNull!.id;
      }

      switch (draft.intent) {
        case VoiceIntentType.sale:
          return _saveSale(draft, partyId: partyId!, itemId: itemId!);
        case VoiceIntentType.purchase:
          return _savePurchase(draft, partyId: partyId!, itemId: itemId!);
        case VoiceIntentType.paymentReceived:
          return _savePayment(draft, partyId: partyId!, isReceived: true);
        case VoiceIntentType.paymentPaid:
          return _savePayment(draft, partyId: partyId!, isReceived: false);
        case VoiceIntentType.expense:
          return _saveExpense(draft);
        case VoiceIntentType.createParty:
          if (partyId != null) return const Success(null);
          final created = await _createParty(draft.partyName!);
          if (created.isFailure) return Error(created.failureOrNull!);
          return const Success(null);
        case VoiceIntentType.createItem:
          if (itemId != null) return const Success(null);
          final created = await _createItem(
            name: draft.itemName!,
            unit: draft.unit ?? ItemUnits.defaultUnit,
          );
          if (created.isFailure) return Error(created.failureOrNull!);
          return const Success(null);
        case VoiceIntentType.unknown:
          return const Error(ValidationFailure('Command samajh nahi aaya'));
      }
    } finally {
      notifyDataChanged(_ref);
    }
  }

  Future<Result<PartySnapshot>> _createParty(String name) async {
    final result = await _ref.read(savePartyUseCaseProvider)(
      SavePartyInput(
        name: name,
        type: PartyType.both,
        phone: '',
        address: '',
        openingAmount: 0,
        openingDirection: OpeningBalanceDirection.receivable,
        isActive: true,
      ),
    );
    if (result.isFailure) return Error(result.failureOrNull!);
    final party = result.valueOrNull!;
    return Success(PartySnapshot(id: party.id, name: party.name));
  }

  Future<Result<ItemSnapshot>> _createItem({
    required String name,
    required String unit,
  }) async {
    final result = await _ref.read(saveItemUseCaseProvider)(
      SaveItemInput(name: name, unit: unit),
    );
    if (result.isFailure) return Error(result.failureOrNull!);
    final item = result.valueOrNull!;
    return Success(ItemSnapshot(id: item.id, name: item.name));
  }

  Future<Result<void>> _saveSale(
    VoiceDraft draft, {
    required String partyId,
    required String itemId,
  }) async {
    final total = draft.lineTotal;
    final breakdown = draft.paymentBreakdown.clampToTotal(total);
    final due = breakdown.remainingCredit(total);

    final result = await _ref.read(saveSaleUseCaseProvider)(
      SaveSaleInput(
        date: DateTime.now(),
        partyId: partyId,
        paymentMode: due > 0 ? PaymentMode.credit : PaymentMode.cash,
        gstType: GstType.intra,
        paymentBreakdown: breakdown,
        paidAmount: breakdown.paidTotal,
        reminderDate: due > 0 ? draft.reminderDate : null,
        notes: draft.notes,
        lines: [
          SaleLineInput(
            itemId: itemId,
            itemName: draft.itemName!,
            qty: draft.quantity!,
            rate: draft.rate!,
            gstRate: 0,
          ),
        ],
      ),
    );
    if (result.isFailure) return Error(result.failureOrNull!);
    return const Success(null);
  }

  Future<Result<void>> _savePurchase(
    VoiceDraft draft, {
    required String partyId,
    required String itemId,
  }) async {
    final total = draft.lineTotal;
    final breakdown = draft.paymentBreakdown.clampToTotal(total);
    final due = breakdown.remainingCredit(total);

    final result = await _ref.read(savePurchaseUseCaseProvider)(
      SavePurchaseInput(
        date: DateTime.now(),
        partyId: partyId,
        paymentMode: due > 0 ? PaymentMode.credit : PaymentMode.cash,
        gstType: GstType.intra,
        paymentBreakdown: breakdown,
        paidAmount: breakdown.paidTotal,
        reminderDate: due > 0 ? draft.reminderDate : null,
        notes: draft.notes,
        lines: [
          PurchaseLineInput(
            itemId: itemId,
            itemName: draft.itemName!,
            qty: draft.quantity!,
            rate: draft.rate!,
            gstRate: 0,
          ),
        ],
      ),
    );
    if (result.isFailure) return Error(result.failureOrNull!);
    return const Success(null);
  }

  Future<Result<void>> _savePayment(
    VoiceDraft draft, {
    required String partyId,
    required bool isReceived,
  }) async {
    final amount = draft.amount ?? draft.paymentBreakdown.paidTotal;
    final save = _ref.read(savePaymentProvider);
    final result = await save(
      isReceived: isReceived,
      partyId: partyId,
      amount: amount,
      dateTime: DateTime.now(),
      note: draft.notes,
      reminderDate: draft.reminderDate,
      breakdown: draft.paymentBreakdown.paidTotal > 0
          ? draft.paymentBreakdown
          : PaymentBreakdown(cash: amount),
    );
    if (result.isFailure) return Error(result.failureOrNull!);
    return const Success(null);
  }

  Future<Result<void>> _saveExpense(VoiceDraft draft) async {
    final result = await _ref.read(recordExpenseUseCaseProvider)(
      RecordExpenseInput(
        name: draft.expenseName!,
        amount: draft.amount!,
        date: DateTime.now(),
        note: draft.notes,
      ),
    );
    if (result.isFailure) return Error(result.failureOrNull!);
    return const Success(null);
  }
}

class PartySnapshot {
  const PartySnapshot({required this.id, required this.name});
  final String id;
  final String name;
}

class ItemSnapshot {
  const ItemSnapshot({required this.id, required this.name});
  final String id;
  final String name;
}
