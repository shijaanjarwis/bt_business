import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/services/logo_storage_service.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/datasources/business_local_datasource.dart';
import '../../data/repositories/business_repository_impl.dart';
import '../../domain/repositories/business_repository.dart';
import '../../domain/usecases/delete_business.dart';
import '../../domain/usecases/get_business.dart';
import '../../domain/usecases/save_business.dart';

final logoStorageServiceProvider = Provider<LogoStorageService>(
  (ref) => LogoStorageService(),
);

final businessLocalDataSourceProvider = Provider<BusinessLocalDataSource>((ref) {
  final database = ref.watch(appDatabaseProvider).requireValue;
  return BusinessLocalDataSource(database);
});

final businessRepositoryProvider = Provider<BusinessRepository>((ref) {
  return BusinessRepositoryImpl(ref.watch(businessLocalDataSourceProvider));
});

final getBusinessUseCaseProvider = Provider<GetBusinessUseCase>((ref) {
  return GetBusinessUseCase(ref.watch(businessRepositoryProvider));
});

final saveBusinessUseCaseProvider = Provider<SaveBusinessUseCase>((ref) {
  return SaveBusinessUseCase(ref.watch(businessRepositoryProvider));
});

final deleteBusinessUseCaseProvider = Provider<DeleteBusinessUseCase>((ref) {
  return DeleteBusinessUseCase(ref.watch(businessRepositoryProvider));
});

/// Whether a business profile exists — drives onboarding redirect.
final businessGateProvider = FutureProvider<bool>((ref) async {
  final result = await ref.watch(getBusinessUseCaseProvider)(const NoParams());
  return result.isSuccess && result.valueOrNull != null;
});

/// Current business profile for display and editing.
final businessProfileProvider = FutureProvider((ref) async {
  final result = await ref.watch(getBusinessUseCaseProvider)(const NoParams());
  if (result.isFailure) {
    throw result.failureOrNull!;
  }
  return result.valueOrNull;
});
