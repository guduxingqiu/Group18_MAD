import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> init() async {
    if (kIsWeb || _ready) return; // not supported on web
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _ready = true;
  }

  static Future<void> showRedZoneAlert(String body) async {
    if (kIsWeb || !_ready) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'red_zone',
        'Red Zone alerts',
        channelDescription: 'Warnings when you are near a verified outbreak',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      id: 1,
      title: 'Red Zone warning',
      body: body,
      notificationDetails: details,
    );
  }
}