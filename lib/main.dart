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
import 'core/shortcuts/launcher_shortcut_service.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
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
  late final WidgetsBindingObserver _coordinator;

  @override
  void initState() {
    super.initState();
    _coordinator = ref.read(appSessionCoordinatorProvider.notifier);
    WidgetsBinding.instance.addObserver(_coordinator);
    LauncherShortcutService.instance.initialize(ref);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_coordinator);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: LauncherShortcutService.navigatorKey,
      title: 'MINOVA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: ref.watch(languageControllerProvider).language.locale,
      supportedLocales: AppLanguage.all.map((language) => language.locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const SplashScreen(),
    );
  }
}

