import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/data_revision.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/router/router_refresh_notifier.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/app_form_section.dart';
import '../../../../shared/widgets/layout/responsive_form_container.dart';
import '../../domain/entities/business.dart';
import '../../domain/entities/currency.dart';
import '../../domain/entities/financial_year.dart';
import '../../domain/usecases/delete_business.dart';
import '../../domain/usecases/save_business.dart';
import '../providers/business_providers.dart';
import '../widgets/business_logo_picker.dart';
import '../widgets/business_settings_fields.dart';

enum BusinessProfileMode { setup, edit }

/// Create, edit, or delete the business profile.
class BusinessProfilePage extends ConsumerStatefulWidget {
  const BusinessProfilePage({
    super.key,
    required this.mode,
  });

  final BusinessProfileMode mode;

  @override
  ConsumerState<BusinessProfilePage> createState() =>
      _BusinessProfilePageState();
}

class _BusinessProfilePageState extends ConsumerState<BusinessProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _gstinController = TextEditingController();

  Business? _existingBusiness;
  String? _logoPath;
  String? _pendingLogoPath;
  bool _removeLogo = false;
  int _financialYearStartMonth = FinancialYear.defaultStartMonth;
  BusinessCurrency _currency = BusinessCurrency.inr;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _gstinController.dispose();
    super.dispose();
  }

  void _initializeFromBusiness(Business? business) {
    if (_initialized) return;

    _existingBusiness = business;
    if (business != null) {
      _nameController.text = business.name;
      _addressController.text = business.address;
      _phoneController.text = business.phone;
      _emailController.text = business.email;
      _gstinController.text = business.gstin ?? '';
      _logoPath = business.logoPath;
      _financialYearStartMonth = business.financialYearStartMonth;
      _currency = business.currency;
    }

    _initialized = true;
  }

  SaveBusinessParams _buildParams({String? logoPath, bool? removeLogo}) {
    return SaveBusinessParams(
      id: _existingBusiness?.id,
      name: _nameController.text,
      address: _addressController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      gstin: _gstinController.text,
      logoPath: logoPath,
      removeLogo: removeLogo ?? _removeLogo,
      financialYearStartMonth: _financialYearStartMonth,
      currency: _currency,
      existingCreatedAt: _existingBusiness?.createdAt,
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final saveBusiness = ref.read(saveBusinessUseCaseProvider);
      final logoStorage = ref.read(logoStorageServiceProvider);
      final initialLogoPath =
          _removeLogo && _pendingLogoPath == null ? null : _logoPath;

      var result = await saveBusiness(
        _buildParams(logoPath: initialLogoPath, removeLogo: false),
      );

      if (result.isFailure) {
        _showMessage(result.failureOrNull!.message);
        return;
      }

      var business = result.valueOrNull!;

      if (_pendingLogoPath != null) {
        if (_logoPath != null) {
          await logoStorage.deleteLogo(_logoPath);
        }
        final persistedPath = await logoStorage.persistLogo(
          businessId: business.id,
          sourcePath: _pendingLogoPath!,
        );
        result = await saveBusiness(
          _buildParams(logoPath: persistedPath, removeLogo: false).copyWithId(
            business.id,
            existingCreatedAt: business.createdAt,
          ),
        );
      } else if (_removeLogo && _logoPath != null) {
        await logoStorage.deleteLogo(_logoPath);
        result = await saveBusiness(
          _buildParams(logoPath: null, removeLogo: true).copyWithId(
            business.id,
            existingCreatedAt: business.createdAt,
          ),
        );
      }

      if (!mounted) return;

      if (result.isFailure) {
        _showMessage(result.failureOrNull!.message);
        return;
      }

      ref.invalidate(businessGateProvider);
      ref.invalidate(businessProfileProvider);
      notifyDataChanged(ref);
      ref.read(routerRefreshNotifierProvider).refresh();

      if (widget.mode == BusinessProfileMode.setup) {
        context.go(RouteNames.home);
      } else {
        _showMessage('Business profile saved');
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDelete() async {
    final business = _existingBusiness;
    if (business == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Business Profile?'),
        content: const Text(
          'This will remove your business details from this device. '
          'You will need to set up your profile again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF3B30),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      await ref.read(logoStorageServiceProvider).deleteLogo(business.logoPath);
      final result = await ref.read(deleteBusinessUseCaseProvider)(
        DeleteBusinessParams(id: business.id),
      );

      if (!mounted) return;

      if (result.isFailure) {
        _showMessage(result.failureOrNull!.message);
        return;
      }

      ref.invalidate(businessGateProvider);
      ref.invalidate(businessProfileProvider);
      notifyDataChanged(ref);
      ref.read(routerRefreshNotifierProvider).refresh();
      context.go(RouteNames.businessProfile);
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(businessProfileProvider);

    return PopScope(
      canPop: widget.mode == BusinessProfileMode.edit && !_isSaving,
      child: Scaffold(
        backgroundColor: ColorPalette.background,
        appBar: AppBar(
          title: Text(
            widget.mode == BusinessProfileMode.setup
                ? 'Set Up Business'
                : 'Business Profile',
          ),
          centerTitle: true,
          automaticallyImplyLeading: widget.mode == BusinessProfileMode.edit,
        ),
        body: profileAsync.when(
          loading: () => const AppLoadingView(),
          error: (error, _) => AppErrorView(
            title: 'Profile load nahi ho paya',
            message: error.toString(),
            actionLabel: 'Try Again',
            onAction: () => ref.invalidate(businessProfileProvider),
          ),
          data: (business) {
            _initializeFromBusiness(business);

            return SafeArea(
              child: ResponsiveFormContainer(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      Center(
                        child: BusinessLogoPicker(
                          logoPath: _removeLogo
                              ? null
                              : (_pendingLogoPath ?? _logoPath),
                          onPick: (path) {
                            setState(() {
                              _pendingLogoPath = path;
                              _removeLogo = false;
                            });
                          },
                          onRemove: () {
                            setState(() {
                              _pendingLogoPath = null;
                              _removeLogo = true;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      AppFormSection(
                        title: 'Business Details',
                        child: Column(
                          children: [
                            AppTextField(
                              label: 'Business Name',
                              controller: _nameController,
                              hint: 'Bharat Traders',
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              validator: (value) => Validators.requiredText(
                                value,
                                fieldName: 'Business name',
                              ),
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'Address',
                              controller: _addressController,
                              hint: 'Shop address',
                              maxLines: 3,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'Phone',
                              controller: _phoneController,
                              hint: '9876543210',
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              validator: Validators.indianPhone,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'Email',
                              controller: _emailController,
                              hint: 'business@example.com',
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: Validators.email,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'GSTIN (optional)',
                              controller: _gstinController,
                              hint: '27AAPFU0939F1ZV',
                              textCapitalization: TextCapitalization.characters,
                              textInputAction: TextInputAction.done,
                              validator: Validators.gstin,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppFormSection(
                        title: 'Accounting Settings',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Financial Year Starts',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: ColorPalette.labelSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            FinancialYearPicker(
                              value: _financialYearStartMonth,
                              onChanged: (month) {
                                setState(() => _financialYearStartMonth = month);
                              },
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Period: ${FinancialYear.rangeLabel(_financialYearStartMonth)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: ColorPalette.labelSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Currency',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: ColorPalette.labelSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            CurrencyPicker(
                              value: _currency,
                              onChanged: (currency) {
                                setState(() => _currency = currency);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      AppPrimaryButton(
                        label: widget.mode == BusinessProfileMode.setup
                            ? 'Save & Continue'
                            : 'Save Changes',
                        isLoading: _isSaving,
                        onPressed: _handleSave,
                      ),
                      if (widget.mode == BusinessProfileMode.edit &&
                          _existingBusiness != null) ...[
                        const SizedBox(height: 12),
                        AppPrimaryButton(
                          label: 'Delete Business Profile',
                          isLoading: _isDeleting,
                          destructive: true,
                          onPressed: _isSaving ? null : _handleDelete,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

extension on SaveBusinessParams {
  SaveBusinessParams copyWithId(
    String id, {
    required DateTime existingCreatedAt,
  }) {
    return SaveBusinessParams(
      id: id,
      name: name,
      address: address,
      phone: phone,
      email: email,
      gstin: gstin,
      logoPath: logoPath,
      removeLogo: removeLogo,
      financialYearStartMonth: financialYearStartMonth,
      currency: currency,
      existingCreatedAt: existingCreatedAt,
    );
  }
}
