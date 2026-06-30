import '../../../../core/errors/result.dart';
import '../entities/business.dart';

/// Persistence contract for the business profile.
abstract interface class BusinessRepository {
  Future<Result<Business?>> getBusiness();

  Future<Result<Business>> saveBusiness(Business business);

  Future<Result<void>> deleteBusiness(String id);
}
