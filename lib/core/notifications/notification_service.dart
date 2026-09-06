import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
  NotificationService({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  static final NotificationService instance = NotificationService();
  final FirebaseMessaging _messaging;

  Stream<RemoteMessage> get messages => FirebaseMessaging.onMessage;

  Future<String?> initialize() async {
    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      return await _messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
    } catch (_) {}
  }
}
