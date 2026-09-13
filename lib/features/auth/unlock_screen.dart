import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/app_security_config.dart';
import '../../core/auth/biometric_service.dart';
import '../../core/shortcuts/launcher_shortcut_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/minova_logo.dart';
import '../shell/main_navigation_shell.dart';
import 'login_screen.dart';

/// Production Unlock Screen featuring fast 6-digit MPIN validation,
/// biometric quick unlock, retry protection, and non-destructive Forgot MPIN recovery.
class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  String _enteredPin = '';
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndTriggerBiometrics();
    });
  }

  Future<void> _checkAndTriggerBiometrics() async {
    final securityState = ref.read(appSessionCoordinatorProvider);
    if (securityState.biometricAvailable && securityState.biometricEnabled) {
      await _tryBiometricUnlock();
    }
  }

  Future<void> _tryBiometricUnlock() async {
    final result = await ref
        .read(appSessionCoordinatorProvider.notifier)
        .authenticateBiometric();

    if (result == BiometricAuthResult.success && mounted) {
      _navigateToHome();
    }
  }

  void _onDigitPressed(String digit) {
    if (_isLoading) return;
    final securityState = ref.read(appSessionCoordinatorProvider);
    if (securityState.isLockedOut) {
      setState(() {
        _errorMessage =
            'Too many failed attempts. Try again in ${securityState.remainingLockoutSeconds}s.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      if (_enteredPin.length < AppSecurityConfig.mpinLength) {
        _enteredPin += digit;
        if (_enteredPin.length == AppSecurityConfig.mpinLength) {
          _verifyPin();
        }
      }
    });
  }

  void _onDeletePressed() {
    if (_isLoading) return;
    setState(() {
      _errorMessage = null;
      if (_enteredPin.isNotEmpty) {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      }
    });
  }

  Future<void> _verifyPin() async {
    setState(() => _isLoading = true);
    try {
      final success = await ref
          .read(appSessionCoordinatorProvider.notifier)
          .verifyMpin(_enteredPin);

      if (success && mounted) {
        _navigateToHome();
      } else if (mounted) {
        setState(() {
          _enteredPin = '';
          _errorMessage = 'Incorrect MPIN. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _enteredPin = '';
          _errorMessage = e is FormatException ? e.message : 'Unlock failed.';
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToHome() {
    final pendingShortcutScreen =
        LauncherShortcutService.instance.consumePendingTargetScreen(ref);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainNavigationShell(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 200),
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

  Future<void> _handleForgotMpin() async {
    final user = ref.read(authStateProvider);
    final userEmail = user?.email ?? '';
    final emailController = TextEditingController(text: userEmail);
    final passwordController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();
    String? dialogError;
    bool dialogLoading = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text(
            'Reset MPIN',
            style: AppTypography.headlineSm.copyWith(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Re-authenticate with your Firebase password to set a new local MPIN.',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textMediumEmphasis,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  enabled: userEmail.isEmpty,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPinController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New 6-Digit MPIN',
                    prefixIcon: Icon(Icons.pin_outlined),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPinController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New MPIN',
                    prefixIcon: Icon(Icons.pin_outlined),
                    counterText: '',
                  ),
                ),
                if (dialogError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    dialogError!,
                    style: AppTypography.bodySm.copyWith(
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: dialogLoading ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: dialogLoading
                  ? null
                  : () async {
                      final email = emailController.text.trim();
                      final password = passwordController.text;
                      final newPin = newPinController.text.trim();
                      final confirmPin = confirmPinController.text.trim();

                      if (newPin.length != AppSecurityConfig.mpinLength ||
                          !RegExp(r'^\d{6}$').hasMatch(newPin)) {
                        setDialogState(
                            () => dialogError = 'MPIN must be exactly 6 digits.');
                        return;
                      }

                      if (newPin != confirmPin) {
                        setDialogState(
                            () => dialogError = 'MPIN entries do not match.');
                        return;
                      }

                      setDialogState(() {
                        dialogLoading = true;
                        dialogError = null;
                      });

                      try {
                        await ref.read(authStateProvider.notifier).resetMpin(
                              email: email,
                              password: password,
                              newPin: newPin,
                            );

                        if (context.mounted) {
                          Navigator.of(ctx).pop();
                          _navigateToHome();
                        }
                      } catch (e) {
                        setDialogState(() {
                          dialogError = e.toString().replaceFirst('Exception: ', '');
                          dialogLoading = false;
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.black,
              ),
              child: dialogLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text('Reset & Unlock'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    final securityState = ref.watch(appSessionCoordinatorProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            children: [
              const SizedBox(height: 12),
              const MinovaLogo(
                size: 52,
                layout: MinovaLogoLayout.iconOnly,
                theme: MinovaLogoTheme.fullColorDark,
              ),
              const SizedBox(height: 12),
              Text(
                'Enter MPIN',
                style: AppTypography.headlineSm.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user != null
                    ? '${user.fullName} • ${user.assignedMineName.isNotEmpty ? user.assignedMineName : "Statutory Inspection"}'
                    : 'Enter 6-digit MPIN to unlock',
                textAlign: TextAlign.center,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.textMediumEmphasis,
                ),
              ),
              const SizedBox(height: 24),

              // 6 PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  AppSecurityConfig.mpinLength,
                  (index) {
                    final isFilled = index < _enteredPin.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF1E293B),
                        border: Border.all(
                          color: isFilled
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF334155),
                          width: 1.5,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Error or Lockout message
              if (_errorMessage != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7F1D1D).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEF4444)),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySm.copyWith(
                      color: const Color(0xFFFCA5A5),
                    ),
                  ),
                ),

              const Spacer(),

              // Numeric Keypad with Biometric action
              _UnlockKeypad(
                onDigit: _onDigitPressed,
                onDelete: _onDeletePressed,
                onBiometric: (securityState.biometricAvailable &&
                        securityState.biometricEnabled)
                    ? _tryBiometricUnlock
                    : null,
              ),

              const SizedBox(height: 16),

              // Footer Actions: Forgot MPIN & Switch Account
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _handleForgotMpin,
                    child: Text(
                      'Forgot MPIN?',
                      style: AppTypography.labelLg.copyWith(
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await ref.read(authStateProvider.notifier).logout();
                      if (context.mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      }
                    },
                    child: Text(
                      'Switch User',
                      style: AppTypography.labelLg.copyWith(
                        color: AppColors.textMediumEmphasis,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnlockKeypad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onDelete;
  final VoidCallback? onBiometric;

  const _UnlockKeypad({
    required this.onDigit,
    required this.onDelete,
    this.onBiometric,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < 3; row++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var col = 1; col <= 3; col++)
                  _KeypadButton(
                    label: '${row * 3 + col}',
                    onTap: () => onDigit('${row * 3 + col}'),
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Biometric or empty
              onBiometric != null
                  ? InkWell(
                      onTap: onBiometric,
                      borderRadius: BorderRadius.circular(36),
                      child: Container(
                        width: 72,
                        height: 72,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                          border: Border.all(
                            color: const Color(0xFF0284C7),
                            width: 1.0,
                          ),
                        ),
                        child: const Icon(
                          Icons.fingerprint_rounded,
                          color: Color(0xFF38BDF8),
                          size: 32,
                        ),
                      ),
                    )
                  : const SizedBox(width: 72, height: 72),

              _KeypadButton(
                label: '0',
                onTap: () => onDigit('0'),
              ),

              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(36),
                child: Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF1E293B),
                  ),
                  child: const Icon(
                    Icons.backspace_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _KeypadButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1E293B),
          border: Border.all(
            color: const Color(0xFF334155),
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.headlineSm.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
