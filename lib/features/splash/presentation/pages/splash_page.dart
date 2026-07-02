import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/user_error_messages.dart';
import '../../../../core/logging/startup_trace.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/branding/app_branding.dart';
import '../../../../features/business/presentation/providers/business_providers.dart';

/// Premium launch screen — purple background, logo, fade to dashboard.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  static const _startupTimeout = Duration(seconds: 45);

  late final AnimationController _fadeController;
  late final Animation<double> _contentOpacity;
  late final Animation<double> _logoScale;

  bool _navigating = false;
  String? _startupError;

  @override
  void initState() {
    super.initState();
    StartupTrace.log('START splash');
    _fadeController = AnimationController(
      vsync: this,
      duration: AppBranding.splashFadeDuration,
      value: 1,
    );
    _contentOpacity = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _logoScale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOutCubic,
      ),
    );
    _fadeController.forward(from: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_finishSplash());
    });
  }

  Future<void> _finishSplash() async {
    if (_navigating) return;

    if (mounted) {
      setState(() => _startupError = null);
    }

    try {
      final gateFuture = ref.read(businessGateProvider.future);
      await Future.wait<Object?>([
        Future<void>.delayed(AppBranding.splashDuration),
        gateFuture,
      ]).timeout(_startupTimeout);

      if (!mounted) return;

      final hasBusiness = await gateFuture;
      await _navigateAway(hasBusiness);
    } catch (error, stackTrace) {
      StartupTrace.log('FAIL splash startup: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _startupError = UserErrorMessages.from(error));
    }
  }

  Future<void> _navigateAway(bool hasBusiness) async {
    if (_navigating) return;
    _navigating = true;

    _fadeController.reverse(from: 1);
    await Future<void>.delayed(AppBranding.splashFadeDuration);
    if (!mounted) return;

    final router = GoRouter.maybeOf(context);
    if (router == null) {
      _navigating = false;
      return;
    }

    StartupTrace.log(
      hasBusiness ? 'START dashboard navigation' : 'START onboarding navigation',
    );
    context.go(hasBusiness ? RouteNames.home : RouteNames.businessProfile);
  }

  void _retryStartup() {
    _navigating = false;
    _fadeController.forward(from: 0);
    unawaited(_finishSplash());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.splashBackground,
      body: FadeTransition(
        opacity: _contentOpacity,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: _startupError == null
                ? _SplashContent(logoScale: _logoScale)
                : _SplashErrorContent(
                    message: _startupError!,
                    onRetry: _retryStartup,
                  ),
          ),
        ),
      ),
    );
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent({required this.logoScale});

  final Animation<double> logoScale;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: logoScale,
          child: const _SplashLogo(),
        ),
        const SizedBox(height: 28),
        const Text(
          AppBranding.appName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          AppBranding.splashTagline,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 40),
        const SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _SplashErrorContent extends StatelessWidget {
  const _SplashErrorContent({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          size: 48,
          color: Colors.white,
        ),
        const SizedBox(height: 20),
        const Text(
          'Shuru nahi ho paya',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.white70,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
        FilledButton(
          onPressed: onRetry,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: ColorPalette.purple,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          ),
          child: const Text(
            'Phir se try karein',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(14),
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
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
        },
      ),
    );
  }
}
