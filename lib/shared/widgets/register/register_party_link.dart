import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/color_palette.dart';
import '../../../shared/utils/register_party_label.dart';
import '../labels/bilingual_label.dart';

/// Tappable party name — opens full party profile from register detail screens.
class RegisterPartyHeaderLink extends StatelessWidget {
  const RegisterPartyHeaderLink({
    super.key,
    required this.partyId,
    required this.partyName,
    this.cashCustomerPartyId,
    this.displayName,
  });

  final String partyId;
  final String partyName;
  final String? cashCustomerPartyId;
  final String? displayName;

  bool get _isLinkable => !RegisterPartyLabel.isCashCustomerParty(
        partyId: partyId,
        partyName: partyName,
        cashCustomerPartyId: cashCustomerPartyId,
      );

  String get _title => displayName ??
      partyName.trim();

  void _openProfile(BuildContext context) {
    context.push(RouteNames.ledgerPartyDetailPath(partyId));
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLinkable) {
      return Text(
        _title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: ColorPalette.labelPrimary,
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openProfile(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: ColorPalette.purple,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: ColorPalette.purple,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Detail-row style tappable party — matches [RegisterDetailRow] layout.
class RegisterDetailPartyRow extends StatelessWidget {
  const RegisterDetailPartyRow({
    super.key,
    required this.partyId,
    required this.partyName,
    this.cashCustomerPartyId,
    this.displayName,
    this.english = 'Party',
    this.hindi = 'Party',
  });

  final String partyId;
  final String partyName;
  final String? cashCustomerPartyId;
  final String? displayName;
  final String english;
  final String hindi;

  bool get _isLinkable => !RegisterPartyLabel.isCashCustomerParty(
        partyId: partyId,
        partyName: partyName,
        cashCustomerPartyId: cashCustomerPartyId,
      );

  String get _title => displayName ?? partyName.trim();

  void _openProfile(BuildContext context) {
    context.push(RouteNames.ledgerPartyDetailPath(partyId));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: BilingualLabel(
              english: english,
              hindi: hindi,
              compact: true,
            ),
          ),
          Expanded(
            flex: 3,
            child: _isLinkable
                ? Align(
                    alignment: Alignment.centerRight,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _openProfile(context),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  _title,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: ColorPalette.purple,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: ColorPalette.purple,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : Text(
                    _title,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: ColorPalette.labelPrimary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
