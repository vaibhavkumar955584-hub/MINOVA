import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/localization/app_language.dart';
import 'core/localization/language_controller.dart';
import 'core/localization/generated/app_localizations.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/notifications/notification_service.dart';
import 'core/sync/background_sync_service.dart';
import 'core/auth/secure_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/language_selection_screen.dart';
import 'features/auth/local_security_gate.dart';
import 'features/shell/main_navigation_shell.dart';
import 'shared/providers/app_providers.dart';

Future<void> main() async {
  final stopwatch = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Critical Initialization: Firebase core & local preferences
  await FirebaseBootstrap.initialize();
  final preferences = await SharedPreferences.getInstance();

  // Desktop / FFI SQLite initialization for test and desktop runs
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // 2. Non-blocking Background Service initialization (runs concurrently without delaying first frame)
  if (!kIsWeb && Platform.isAndroid && FirebaseBootstrap.isConfigured) {
    Future.wait([
      NotificationService.instance.initialize(),
      BackgroundSyncService.instance.initialize(),
    ]).catchError((e) {
      if (kDebugMode) {
        debugPrint('[Startup] Non-critical background service init failed: $e');
      }
      return <void>[];
    });
  }

  if (kDebugMode) {
    debugPrint('[Startup] Critical path completed in ${stopwatch.elapsedMilliseconds}ms. Launching UI.');
  }

  runApp(
    ProviderScope(
      overrides: [
        languageControllerProvider.overrideWith(
          (ref) => LanguageController(preferences: preferences),
        ),
      ],
      child: const MineSafeApp(),
    ),
  );
}

class MineSafeApp extends ConsumerStatefulWidget {
  const MineSafeApp({super.key});

  @override
  ConsumerState<MineSafeApp> createState() => _MineSafeAppState();
}

class _MineSafeAppState extends ConsumerState<MineSafeApp> {
  bool _isCheckingSession = true;
  bool _isSessionUnlocked = false;

  @override
  void initState() {
    super.initState();
    _checkSavedSession();
  }

  Future<void> _checkSavedSession() async {
    try {
      await ref.read(authStateProvider.notifier).restoreSession();
      final isUnlocked = await SecureTokenStorage.instance.isSessionUnlocked();
      if (mounted) {
        setState(() {
          _isSessionUnlocked = isUnlocked;
        });
      }
      if (isUnlocked) {
        ref.read(sessionUnlockedProvider.notifier).state = true;
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingSession = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    final isUnlocked = ref.watch(sessionUnlockedProvider) || _isSessionUnlocked;

    return MaterialApp(
      title: 'MINOVA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: ref.watch(languageControllerProvider).language.locale,
      supportedLocales: AppLanguage.all.map((language) => language.locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: _isCheckingSession
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
              ),
            )
          : (!ref.watch(languageControllerProvider).hasSelection
                ? const LanguageSelectionScreen()
                : (user != null
                      ? (isUnlocked
                            ? const MainNavigationShell()
                            : const LocalSecurityGate())
                      : const LoginScreen())),
    );
  }
}
