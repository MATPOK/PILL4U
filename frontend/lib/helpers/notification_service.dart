import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Warsaw'));

    // Używamy głównej ikony aplikacji, żeby uniknąć wywalania powiadomień
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    // POPRAWKA: Przywrócone "settings:"
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Tu zrobimy przekierowanie po kliknięciu
      },
    );

    // Od razu przy starcie apki wymuszamy okienka z prośbą o zgody!
    await requestPermissions();
  }

  Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  Future<void> scheduleMedicationNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required List<int> daysOfWeek,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'medication_channel',
      'Powiadomienia o lekach',
      channelDescription: 'Przypomnienia o wzięciu leków o wyznaczonej godzinie',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF007AFF),
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    final now = tz.TZDateTime.now(tz.local);

    for (int day in daysOfWeek) {
      tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

      while (scheduledDate.weekday != day) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 7));
      }

      final uniqueId = int.parse('$id$day');

      // POPRAWKA: Przywrócone "id:", "title:", "body:" itd.
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: uniqueId,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}