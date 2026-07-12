import 'package:bt_business/core/errors/user_error_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/backup/backup_format.dart';
import '../../../../core/backup/backup_providers.dart';
import '../../../../core/di/data_revision.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/router/router_refresh_notifier.dart';
import '../../../../core/theme/app_text_theme.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/branding/developer_footer.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/dialogs/confirmation_dialog.dart';
import '../../../../shared/widgets/feedback/app_error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_view.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/labels/app_form_field_label.dart';
import '../../../../shared/widgets/layout/app_form_section.dart';
import '../../../../shared/widgets/layout/responsive_form_container.dart';
import '../../../../shared/widgets/scaffold/app_register_app_bar.dart';
import '../../../../shared/widgets/settings/language_picker.dart';
import '../../../backup/presentation/widgets/auto_backup_setup_dialog.dart';
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
  bool _initScheduled = false;

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

  void _scheduleInitializeFromBusiness(Business? business) {
    if (_initialized || _initScheduled) return;
    _initScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _initialized) return;
      setState(() => _initializeFromBusiness(business));
    });
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
      SchedulerBinding.instance.addPostFrameCallback((_) {
        ref.read(routerRefreshNotifierProvider).refresh();
      });

      if (widget.mode == BusinessProfileMode.setup) {
        final metadata = ref.read(backupMetadataStoreProvider);
        if (!await metadata.autoBackupPromptShown()) {
          await metadata.markAutoBackupPromptShown();
          if (!mounted) return;
          final enable = await AutoBackupSetupDialog.show(context);
          if (enable == true) {
            await metadata.setAutoBackupEnabled(true);
            await metadata.setAutoFrequency(AutoBackupFrequency.daily);
          } else {
            await metadata.setAutoBackupEnabled(false);
          }
        }
        if (!mounted) return;
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

    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Business Profile?',
      message:
          'This will remove your business details from this device. '
          'You will need to set up your profile again.',
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
      SchedulerBinding.instance.addPostFrameCallback((_) {
        ref.read(routerRefreshNotifierProvider).refresh();
      });
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
        appBar: AppRegisterAppBar(
          english: widget.mode == BusinessProfileMode.setup
              ? 'Set Up Business'
              : 'Business Profile',
          hindi: widget.mode == BusinessProfileMode.setup
              ? 'Dukaan Setup'
              : 'Dukaan Profile',
          leading: widget.mode == BusinessProfileMode.setup
              ? const SizedBox.shrink()
              : null,
        ),
        body: profileAsync.when(
          loading: () => const AppLoadingView(),
          error: (error, _) => AppErrorView(
            title: 'Profile load nahi ho paya',
            message: UserErrorMessages.from(error),
            actionEnglish: 'Try Again', actionHindi: 'Phir Try Karein',
            onAction: () => ref.invalidate(businessProfileProvider),
          ),
          data: (business) {
            _scheduleInitializeFromBusiness(business);

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
                        english: 'Business Details',
                        hindi: 'Dukaan Ki Detail',
                        child: Column(
                          children: [
                            AppTextField(
                              english: 'Business Name',
                              hindi: 'Dukaan ka Naam',
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              validator: (value) => Validators.requiredText(
                                value,
                                fieldName: 'Dukaan ka naam',
                              ),
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              english: 'Address',
                              hindi: 'Pata',
                              controller: _addressController,
                              maxLines: 3,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              english: 'Phone',
                              hindi: 'Mobile',
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              validator: Validators.indianPhone,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              english: 'Email',
                              hindi: 'Email',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: Validators.email,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              english: 'GSTIN',
                              hindi: 'GSTIN',
                              controller: _gstinController,
                              helper: 'Optional',
                              textCapitalization: TextCapitalization.characters,
                              textInputAction: TextInputAction.done,
                              validator: Validators.gstin,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppFormSection(
                        english: 'Settings',
                        hindi: 'Settings',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppFormFieldLabel(
                              english: 'Financial Year Starts',
                              hindi: 'Saal Kab Shuru',
                              compact: true,
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
                            const AppFormFieldLabel(
                              english: 'Currency',
                              hindi: 'Paisa',
                              compact: true,
                            ),
                            const SizedBox(height: 8),
                            CurrencyPicker(
                              value: _currency,
                              onChanged: (currency) {
                                setState(() => _currency = currency);
                              },
                            ),
                            const SizedBox(height: 20),
                            const AssistantLanguagePicker(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppFormSection(
                        english: 'Data Safety',
                        hindi: 'Data Suraksha',
                        child: Material(
                          color: Colors.transparent,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.shield_outlined,
                              color: ColorPalette.purple,
                            ),
                            title: Text(
                              'Backup & Restore',
                              style: context.appText.primaryBold.copyWith(fontSize: 16),
                            ),
                            subtitle: Text(
                              'Copy kahan save hogi — setup karein',
                              style: context.appText.secondary.copyWith(fontSize: 14),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: ColorPalette.iconPrimary,
                            ),
                            onTap: () => context.push(RouteNames.backup),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      AppPrimaryButton(
                        english: widget.mode == BusinessProfileMode.setup
                            ? 'Continue'
                            : 'Update',
                        hindi: widget.mode == BusinessProfileMode.setup
                            ? 'Aage Badhein'
                            : 'Badlein',
                        isLoading: _isSaving,
                        onPressed: _handleSave,
                      ),
                      if (widget.mode == BusinessProfileMode.edit &&
                          _existingBusiness != null) ...[
                        const SizedBox(height: 12),
                        AppPrimaryButton(
                          english: 'Delete',
                          hindi: 'Delete Karein',
                          isLoading: _isDeleting,
                          destructive: true,
                          onPressed: _isSaving ? null : _handleDelete,
                        ),
                      ],
                      const DeveloperFooter(),
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
