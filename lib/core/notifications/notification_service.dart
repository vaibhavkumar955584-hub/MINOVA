import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../models/emergency_notification_model.dart';
import 'emergency_notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    final notification = EmergencyNotificationModel.fromRemoteMessage(message);
    await EmergencyNotificationService.instance.initialize();
    await EmergencyNotificationService.instance.addNotification(notification);
  } catch (_) {}
}

class NotificationService {
  NotificationService({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  static final NotificationService instance = NotificationService();
  final FirebaseMessaging _messaging;

  Stream<RemoteMessage> get messages => FirebaseMessaging.onMessage;

  Future<String?> initialize() async {
    try {
      await EmergencyNotificationService.instance.initialize();
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Handle foreground notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        try {
          final notification = EmergencyNotificationModel.fromRemoteMessage(message);
          await EmergencyNotificationService.instance.addNotification(notification);
        } catch (_) {}
      });

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
