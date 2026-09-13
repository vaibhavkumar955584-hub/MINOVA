import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/app_security_config.dart';
import '../../core/shortcuts/launcher_shortcut_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/minova_logo.dart';
import '../shell/main_navigation_shell.dart';

/// Screen guiding newly authenticated inspectors through mandatory 6-digit MPIN setup
/// and optional biometric enrollment.
class SetupSecurityScreen extends ConsumerStatefulWidget {
  const SetupSecurityScreen({super.key});

  @override
  ConsumerState<SetupSecurityScreen> createState() =>
      _SetupSecurityScreenState();
}

class _SetupSecurityScreenState extends ConsumerState<SetupSecurityScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  bool _enableBiometric = false;
  String? _errorMessage;
  bool _isLoading = false;

  void _onDigitPressed(String digit) {
    if (_isLoading) return;
    setState(() {
      _errorMessage = null;
      if (!_isConfirming) {
        if (_pin.length < AppSecurityConfig.mpinLength) {
          _pin += digit;
          if (_pin.length == AppSecurityConfig.mpinLength) {
            _isConfirming = true;
          }
        }
      } else {
        if (_confirmPin.length < AppSecurityConfig.mpinLength) {
          _confirmPin += digit;
          if (_confirmPin.length == AppSecurityConfig.mpinLength) {
            _validateAndComplete();
          }
        }
      }
    });
  }

  void _onDeletePressed() {
    if (_isLoading) return;
    setState(() {
      _errorMessage = null;
      if (!_isConfirming) {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      } else {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        } else {
          // Backtrack to pin entry step
          _isConfirming = false;
          _pin = '';
        }
      }
    });
  }

  Future<void> _validateAndComplete() async {
    if (_pin != _confirmPin) {
      setState(() {
        _errorMessage = 'MPIN entries do not match. Please try again.';
        _pin = '';
        _confirmPin = '';
        _isConfirming = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(appSessionCoordinatorProvider.notifier).setupMpin(
            _pin,
            enableBiometric: _enableBiometric,
          );

      if (mounted) {
        final pendingShortcutScreen =
            LauncherShortcutService.instance.consumePendingTargetScreen(ref);

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationShell()),
        );

        if (pendingShortcutScreen != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            LauncherShortcutService.navigatorKey.currentState?.push(
              MaterialPageRoute(builder: (_) => pendingShortcutScreen),
            );
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to configure MPIN: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final securityState = ref.watch(appSessionCoordinatorProvider);
    final currentInput = _isConfirming ? _confirmPin : _pin;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 12),
              const MinovaLogo(
                size: 56,
                layout: MinovaLogoLayout.iconOnly,
                theme: MinovaLogoTheme.fullColorDark,
              ),
              const SizedBox(height: 16),
              Text(
                _isConfirming ? 'Confirm Your MPIN' : 'Set Up Your 6-Digit MPIN',
                style: AppTypography.headlineSm.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isConfirming
                    ? 'Re-enter your 6-digit MPIN for confirmation'
                    : 'Create a secure MPIN for offline shift access',
                textAlign: TextAlign.center,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.textMediumEmphasis,
                ),
              ),
              const SizedBox(height: 24),

              // PIN Indicator Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  AppSecurityConfig.mpinLength,
                  (index) {
                    final isFilled = index < currentInput.length;
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

              // Error banner
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

              // Biometric opt-in toggle (if hardware available)
              if (securityState.biometricAvailable) ...[
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _enableBiometric,
                  onChanged: (val) =>
                      setState(() => _enableBiometric = val ?? false),
                  title: Text(
                    'Enable Biometric Login (Fingerprint/Face)',
                    style: AppTypography.bodySm.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  activeColor: const Color(0xFFF59E0B),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],

              const Spacer(),

              // Numeric Keypad
              _NumericKeypad(
                onDigit: _onDigitPressed,
                onDelete: _onDeletePressed,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumericKeypad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onDelete;

  const _NumericKeypad({
    required this.onDigit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < 3; row++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
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
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 72, height: 72),
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
