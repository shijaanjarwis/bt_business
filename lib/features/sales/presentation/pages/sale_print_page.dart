import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/accounting/gst_types.dart';
import '../../../../core/accounting/payment_modes.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../domain/entities/sale_invoice.dart';
import '../providers/sale_providers.dart';
import '../../../business/presentation/providers/business_providers.dart';

/// Print-ready sales invoice layout.
class SalePrintPage extends ConsumerWidget {
  const SalePrintPage({
    super.key,
    required this.saleId,
  });

  final String saleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saleAsync = ref.watch(saleDetailProvider(saleId));
    final businessAsync = ref.watch(businessProfileProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Tax Invoice · Bill'),
      ),
      body: saleAsync.when(
        loading: () => const AppLoadingView(),
        error: (error, _) => AppErrorView(
          title: 'Invoice load nahi ho payi',
          message: error.toString(),
        ),
        data: (invoice) {
          if (invoice == null) {
            return const AppErrorView(title: 'Invoice not found', message: '');
          }
          return businessAsync.when(
            loading: () => const AppLoadingView(),
            error: (_, _) => _InvoiceBody(invoice: invoice, businessName: 'BT Business'),
            data: (business) => _InvoiceBody(
              invoice: invoice,
              businessName: business?.name ?? 'BT Business',
              businessAddress: business?.address,
              businessPhone: business?.phone,
              businessGstin: business?.gstin,
            ),
          );
        },
      ),
    );
  }
}

class _InvoiceBody extends StatelessWidget {
  const _InvoiceBody({
    required this.invoice,
    required this.businessName,
    this.businessAddress,
    this.businessPhone,
    this.businessGstin,
  });

  final SaleInvoice invoice;
  final String businessName;
  final String? businessAddress;
  final String? businessPhone;
  final String? businessGstin;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                businessName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              if (businessAddress != null && businessAddress!.isNotEmpty)
                Text(businessAddress!, textAlign: TextAlign.center),
              if (businessPhone != null && businessPhone!.isNotEmpty)
                Text('Phone: $businessPhone', textAlign: TextAlign.center),
              if (businessGstin != null && businessGstin!.isNotEmpty)
                Text('GSTIN: $businessGstin', textAlign: TextAlign.center),
              const SizedBox(height: 20),
              const Divider(thickness: 2),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TAX INVOICE', style: TextStyle(fontWeight: FontWeight.w700)),
                      Text('Invoice: ${invoice.invoiceNo}'),
                      Text('Date: ${DateFormatter.shortDate(invoice.date)}'),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Bill To · Grahak'),
                      Text(invoice.partyName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        invoice.paymentMode == PaymentMode.cash
                            ? 'Payment: Cash'
                            : 'Payment: Credit (Udhaar)',
                      ),
                      Text(
                        invoice.gstType == GstType.intra
                            ? 'GST: CGST + SGST'
                            : 'GST: IGST',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _LinesTable(lines: invoice.lines),
              const SizedBox(height: 16),
              _TotalsBlock(invoice: invoice),
              if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Notes: ${invoice.notes}'),
              ],
              const SizedBox(height: 32),
              const Text(
                'Thank you · Dhanyavaad',
                textAlign: TextAlign.center,
                style: TextStyle(color: ColorPalette.labelSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinesTable extends StatelessWidget {
  const _LinesTable({required this.lines});

  final List<SaleLine> lines;

  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(color: Colors.black26),
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(1),
        5: FlexColumnWidth(1.2),
      },
      children: [
        const TableRow(
          decoration: BoxDecoration(color: Color(0xFFF2F2F7)),
          children: [
            _HeaderCell('Item'),
            _HeaderCell('Qty'),
            _HeaderCell('Rate'),
            _HeaderCell('Disc'),
            _HeaderCell('GST%'),
            _HeaderCell('Total'),
          ],
        ),
        ...lines.map(
          (line) => TableRow(
            children: [
              _Cell('${line.itemName}\n${line.hsnSac ?? ''}'),
              _Cell(line.qty.toString()),
              _Cell(line.rate.toStringAsFixed(2)),
              _Cell(line.discountAmount.toStringAsFixed(2)),
              _Cell(line.gstRate.toStringAsFixed(0)),
              _Cell(CurrencyFormatter.format(line.lineTotal)),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _TotalsBlock extends StatelessWidget {
  const _TotalsBlock({required this.invoice});

  final SaleInvoice invoice;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _row('Subtotal', invoice.subtotal),
        _row('Discount', invoice.discountTotal),
        _row('Taxable Amount', invoice.taxableTotal),
        if (invoice.cgstTotal > 0) _row('CGST', invoice.cgstTotal),
        if (invoice.sgstTotal > 0) _row('SGST', invoice.sgstTotal),
        if (invoice.igstTotal > 0) _row('IGST', invoice.igstTotal),
        const Divider(),
        _row('Grand Total · Kul', invoice.grandTotal, bold: true),
      ],
    );
  }

  Widget _row(String label, double amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
          const SizedBox(width: 24),
          SizedBox(
            width: 120,
            child: Text(
              CurrencyFormatter.format(amount),
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
