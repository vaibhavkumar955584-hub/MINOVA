import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/biometric_service.dart';
import '../../core/auth/secure_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/providers/app_providers.dart';
import '../shell/main_navigation_shell.dart';

class LocalSecurityGate extends ConsumerStatefulWidget {
  const LocalSecurityGate({super.key});

  @override
  ConsumerState<LocalSecurityGate> createState() => _LocalSecurityGateState();
}

class _LocalSecurityGateState extends ConsumerState<LocalSecurityGate> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _checking = true;
  bool _needsSetup = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    final mpin = ref.read(mpinServiceProvider);
    final configured = await mpin.isMpinConfigured();
    final biometricAvailable = await ref
        .read(biometricServiceProvider)
        .isAvailable();
    final biometricEnabled = await mpin.isBiometricEnabled();
    if (!mounted) return;
    setState(() {
      _needsSetup = !configured;
      _biometricAvailable = biometricAvailable;
      _biometricEnabled = biometricEnabled;
      _checking = false;
    });
    if (configured && biometricEnabled) await _tryBiometric();
  }

  Future<void> _tryBiometric() async {
    final result = await ref.read(biometricServiceProvider).authenticate();
    if (result == BiometricAuthResult.success) _openHome();
  }

  Future<void> _submit() async {
    final pin = _pinController.text;
    try {
      if (_needsSetup) {
        if (pin != _confirmPinController.text) {
          throw const FormatException('MPIN entries do not match.');
        }
        await ref.read(mpinServiceProvider).setupMpin(pin);
        await ref
            .read(mpinServiceProvider)
            .setBiometricEnabled(_biometricEnabled);
      } else if (!await ref.read(mpinServiceProvider).verifyMpin(pin)) {
        throw const FormatException('Incorrect MPIN.');
      }
      _openHome();
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is FormatException
              ? error.message.toString()
              : 'Could not unlock the app. Try again.',
        );
      }
    }
  }

  Future<void> _resetMpin() async {
    final email = TextEditingController();
    final password = TextEditingController();
    final newPin = TextEditingController();
    final confirmPin = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset MPIN'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: email,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              TextField(
                controller: newPin,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'New six-digit MPIN',
                ),
              ),
              TextField(
                controller: confirmPin,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(labelText: 'Confirm new MPIN'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      email.dispose();
      password.dispose();
      newPin.dispose();
      confirmPin.dispose();
      return;
    }
    try {
      if (newPin.text != confirmPin.text) {
        throw const FormatException('MPIN entries do not match.');
      }
      await ref
          .read(authStateProvider.notifier)
          .resetMpin(
            email: email.text,
            password: password.text,
            newPin: newPin.text,
          );
      setState(() {
        _needsSetup = false;
        _error = null;
      });
    } catch (error) {
      setState(
        () => _error = error is FormatException
            ? error.message.toString()
            : 'Could not reset MPIN. Check your account details.',
      );
    }
    email.dispose();
    password.dispose();
    newPin.dispose();
    confirmPin.dispose();
  }

  Future<void> _openHome() async {
    if (!mounted) return;
    await SecureTokenStorage.instance.markSessionUnlocked();
    ref.read(sessionUnlockedProvider.notifier).state = true;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigationShell()),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryAmber),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(_needsSetup ? 'Secure your app' : 'Unlock MINOVA'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _needsSetup
                      ? 'Secure your MINOVA app with a six-digit MPIN.'
                      : 'Welcome back. Use your MPIN or device biometrics.',
                  style: AppTypography.bodyLg,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Six-digit MPIN',
                  ),
                ),
                if (_needsSetup) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmPinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Confirm six-digit MPIN',
                    ),
                  ),
                  if (_biometricAvailable)
                    OutlinedButton.icon(
                      onPressed: () => setState(
                        () => _biometricEnabled = !_biometricEnabled,
                      ),
                      icon: Icon(
                        _biometricEnabled
                            ? Icons.fingerprint
                            : Icons.fingerprint_outlined,
                      ),
                      label: Text(
                        _biometricEnabled
                            ? 'Device biometrics enabled'
                            : 'Enable device biometrics',
                      ),
                    ),
                ],
                if (_error != null)
                  Text(
                    _error!,
                    style: const TextStyle(color: AppColors.hazardRed),
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(_needsSetup ? 'Continue' : 'Unlock'),
                ),
                if (!_needsSetup && _biometricEnabled)
                  TextButton(
                    onPressed: _tryBiometric,
                    child: const Text('Use device biometrics'),
                  ),
                if (!_needsSetup)
                  TextButton(
                    onPressed: _resetMpin,
                    child: const Text('Forgot MPIN?'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
