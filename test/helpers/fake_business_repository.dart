import 'package:bt_business/core/errors/result.dart';
import 'package:bt_business/features/business/domain/entities/business.dart';
import 'package:bt_business/features/business/domain/repositories/business_repository.dart';

class FakeBusinessRepository implements BusinessRepository {
  Business? savedBusiness;

  @override
  Future<Result<void>> deleteBusiness(String id) async {
    savedBusiness = null;
    return const Success(null);
  }

  @override
  Future<Result<Business?>> getBusiness() async {
    return Success(savedBusiness);
  }

  @override
  Future<Result<Business>> saveBusiness(Business business) async {
    savedBusiness = business;
    return Success(business);
  }
}
