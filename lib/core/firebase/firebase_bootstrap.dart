import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool get isConfigured =>
      DefaultFirebaseOptions.currentPlatform.projectId !=
      DefaultFirebaseOptions.placeholderProjectId;

  static Future<bool> initialize() async {
    if (!isConfigured) return false;
    if (Firebase.apps.isNotEmpty) return true;

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  }
}