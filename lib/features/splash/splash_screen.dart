import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/app_security_state.dart';
import '../../core/localization/language_controller.dart';
import '../../core/shortcuts/launcher_shortcut_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/minova_logo.dart';
import '../auth/language_selection_screen.dart';
import '../auth/login_screen.dart';
import '../auth/setup_security_screen.dart';
import '../auth/unlock_screen.dart';
import '../shell/main_navigation_shell.dart';

/// Production Splash Screen featuring official MINOVA branding,
/// fast non-blocking initialization, and deterministic security/auth destination resolution.
class SplashScreen extends ConsumerStatefulWidget {
  final void Function(Widget destination)? onDestinationResolved;

  const SplashScreen({
    super.key,
    this.onDestinationResolved,
  });

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animController.forward();
    _resolveDestination();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _resolveDestination() async {
    if (kDebugMode) {
      debugPrint('[SPLASH] auth_check=start');
    }

    try {
      // 1. Restore Firebase Auth Session (fast local auth check)
      await ref.read(authStateProvider.notifier).restoreSession();

      // 2. Initialize device-local security posture
      await ref
          .read(appSessionCoordinatorProvider.notifier)
          .initialize(isProcessRestart: true);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SPLASH] Initialization error: $e');
      }
    }

    // Brief presentation delay for clean visual transition (max 500ms)
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final langController = ref.read(languageControllerProvider);
    final user = ref.read(authStateProvider);
    final securitySnapshot = ref.read(appSessionCoordinatorProvider);

    Widget destination;

    if (!langController.hasSelection) {
      if (kDebugMode) debugPrint('[NAV] destination=language_selection');
      destination = const LanguageSelectionScreen();
    } else if (user == null) {
      if (kDebugMode) debugPrint('[NAV] destination=login');
      destination = const LoginScreen();
    } else if (user.accountStatus.toLowerCase() != 'active') {
      if (kDebugMode) debugPrint('[NAV] destination=inactive_account');
      destination = const InactiveAccountScreen();
    } else if (securitySnapshot.state == SecurityState.unconfigured) {
      if (kDebugMode) debugPrint('[NAV] destination=setup_security');
      destination = const SetupSecurityScreen();
    } else if (securitySnapshot.state == SecurityState.locked) {
      if (kDebugMode) debugPrint('[NAV] destination=unlock');
      destination = const UnlockScreen();
    } else {
      if (kDebugMode) debugPrint('[NAV] destination=home');
      destination = const MainNavigationShell();
    }

    if (widget.onDestinationResolved != null) {
      widget.onDestinationResolved!(destination);
    } else {
      final pendingShortcutScreen = (destination is MainNavigationShell)
          ? LauncherShortcutService.instance.consumePendingTargetScreen(ref)
          : null;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, anim1, anim2) => destination,
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 250),
        ),
      );

      if (pendingShortcutScreen != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          LauncherShortcutService.navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => pendingShortcutScreen),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: Stack(
        children: [
          // Background ambient gradient glow
          Positioned(
            top: -100,
            left: -50,
            right: -50,
            height: 350,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFF59E0B).withValues(alpha: 0.08),
                    const Color(0xFF0284C7).withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                  radius: 0.8,
                ),
              ),
            ),
          ),

          // Central Brand Presentation
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const MinovaLogo(
                        size: 110,
                        layout: MinovaLogoLayout.vertical,
                        theme: MinovaLogoTheme.fullColorDark,
                        showTagline: false,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'MINOVA',
                        style: AppTypography.displayLg.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Advanced Mining Intelligence\n& Operations Platform',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySm.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Statutory Compliance Footer
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Center(
              child: Text(
                'DIRECTORATE GENERAL OF MINES SAFETY • STATUTORY COMPLIANCE',
                textAlign: TextAlign.center,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.textDisabled,
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fallback screen for inactive or de-authorized inspector accounts.
class InactiveAccountScreen extends ConsumerWidget {
  const InactiveAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.admin_panel_settings_rounded,
                size: 64,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(height: 20),
              Text(
                'Account Inactive',
                style: AppTypography.headlineMd.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your inspector account is currently inactive or lacks mine authorization.\nPlease contact your mine safety manager or DGMS administrator.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.textMediumEmphasis,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => ref.read(authStateProvider.notifier).logout(),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Return to Login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
