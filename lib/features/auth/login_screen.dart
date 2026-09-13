import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/localization_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/minova_logo.dart';
import 'language_selection_screen.dart';
import 'setup_security_screen.dart';
import 'unlock_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authStateProvider.notifier)
          .loginWithEmail(_emailController.text, _passwordController.text);

      final isMpinConfigured =
          await ref.read(mpinServiceProvider).isMpinConfigured();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => isMpinConfigured
                ? const UnlockScreen()
                : const SetupSecurityScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: context.l10n.language,
            icon: const Icon(Icons.language_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const LanguageSelectionScreen(),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Official MINOVA Brand Logo
                const Center(
                  child: MinovaLogo(
                    size: 80,
                    layout: MinovaLogoLayout.vertical,
                    theme: MinovaLogoTheme.fullColorLight,
                    showTagline: true,
                    customTagline: 'SAFER MINES. A STRONGER TOMORROW.',
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'खनन सुरक्षा एवं वैधानिक अनुपालन प्रणाली • DGMS COMPLIANCE',
                    style: AppTypography.bilingualCue.copyWith(
                      color: AppColors.primaryAmber,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 28),

                // Form Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardLayer1,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.strokeLowLight,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email address',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.textMediumEmphasis,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: AppTypography.bodyLg,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: AppColors.primaryAmber,
                          ),
                          hintText: 'name@example.com',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.l10n.password,
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.textMediumEmphasis,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: AppTypography.bodyLg,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(
                            Icons.lock_outline_rounded,
                            color: AppColors.primaryAmber,
                          ),
                          hintText: '••••••••',
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.hazardRed,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () => _handleLogin(),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.onPrimary,
                                  ),
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      context.l10n.login,
                                      style: AppTypography.labelLg.copyWith(
                                        color: AppColors.onPrimary,
                                      ),
                                    ),
                                    Text(
                                      'फील्ड टर्मिनल में लॉगिन करें',
                                      style: AppTypography.bilingualCue.copyWith(
                                        color: AppColors.onPrimary.withAlpha(200),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                try {
                                  await ref
                                      .read(authStateProvider.notifier)
                                      .sendPasswordResetEmail(
                                        _emailController.text,
                                      );
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Password reset email sent.',
                                      ),
                                    ),
                                  );
                                } catch (error) {
                                  if (mounted) {
                                    setState(
                                      () => _errorMessage = error.toString(),
                                    );
                                  }
                                }
                              },
                        child: const Text('Forgot password?'),
                      ),
                    ],
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
