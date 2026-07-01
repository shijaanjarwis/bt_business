import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/branding/app_branding.dart';
import '../../../../features/business/presentation/providers/business_providers.dart';

/// Premium launch screen — logo, title, then dashboard.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _contentOpacity;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 1,
    );
    _contentOpacity = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _finishSplash());
  }

  Future<void> _finishSplash() async {
    final gateFuture = ref.read(businessGateProvider.future);
    await Future.wait<void>([
      Future<void>.delayed(AppBranding.splashDuration),
      gateFuture.then((_) {}),
    ]);

    if (!mounted) return;

    _fadeController.reverse(from: 1);
    await Future<void>.delayed(const Duration(milliseconds: 380));
    if (!mounted) return;

    final router = GoRouter.maybeOf(context);
    if (router == null) return;

    final hasBusiness = ref.read(businessGateProvider).valueOrNull ?? false;
    context.go(hasBusiness ? RouteNames.home : RouteNames.businessProfile);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _contentOpacity,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SplashLogo(),
                const SizedBox(height: 28),
                const Text(
                  AppBranding.appName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                    color: Color(0xFF1C1C1E),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: ColorPalette.purple.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E5EA)),
        boxShadow: [
          BoxShadow(
            color: ColorPalette.purple.withValues(alpha: 0.06),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(12),
      child: Image.asset(
        AppBranding.logoAssetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ColorPalette.purple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'BT',
              style: TextStyle(
                color: ColorPalette.purple,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
        },
      ),
    );
  }
}
