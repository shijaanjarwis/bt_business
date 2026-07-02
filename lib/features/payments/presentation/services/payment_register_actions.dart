import '../../../../core/errors/exception_mapper.dart';
import '../../../../core/errors/result.dart';
import '../../../ledger/data/services/payment_posting_service.dart';

/// Presentation-layer save/delete for payments — uses existing posting service.
final class PaymentRegisterActions {
  const PaymentRegisterActions(this._postingService);

  final PaymentPostingService _postingService;

  Future<Result<String>> save({
    required String businessId,
    required bool isReceived,
    required String partyId,
    required double amount,
    required DateTime dateTime,
    String? note,
    String? id,
    DateTime? reminderDate,
  }) async {
    try {
      final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);
      final transactionId = isReceived
          ? await _postingService.recordReceived(
              businessId: businessId,
              partyId: partyId,
              amount: amount,
              date: dateOnly,
              note: note,
              id: id,
              existingCreatedAt: dateTime,
              reminderDate: reminderDate,
            )
          : await _postingService.recordPaid(
              businessId: businessId,
              partyId: partyId,
              amount: amount,
              date: dateOnly,
              note: note,
              id: id,
              existingCreatedAt: dateTime,
              reminderDate: reminderDate,
            );
      return Success(transactionId);
    } catch (error, stackTrace) {
      return Error(ExceptionMapper.map(error, stackTrace));
    }
  }

  Future<Result<void>> delete(String id) async {
    try {
      await _postingService.delete(id);
      return const Success(null);
    } catch (error, stackTrace) {
      return Error(ExceptionMapper.map(error, stackTrace));
    }
  }
}
