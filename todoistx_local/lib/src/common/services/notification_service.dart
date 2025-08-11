import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:todoistx_local/src/common/models/task.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
            onDidReceiveLocalNotification: (id, title, body, payload) async {});
    final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (response) async {});
  }

  Future<void> scheduleTaskReminders(Task task) async {
    if (task.reminderTimes == null || task.reminderTimes!.isEmpty) return;

    for (int i = 0; i < task.reminderTimes!.length; i++) {
      final reminderTime = task.reminderTimes![i];
      if (reminderTime.isBefore(DateTime.now())) continue;

      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);
      final notificationId = (task.id + i.toString()).hashCode;

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'task_reminders', 'Task Reminders',
        channelDescription: 'Notifications for task reminders',
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        task.title,
        task.description ?? 'You have a task reminder!',
        scheduledDate,
        platformDetails,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelTaskReminders(Task task) async {
    // We need to cancel all potential notifications for a task.
    // A simple approach is to try to cancel a bunch of them.
    // A more robust approach would store the number of reminders, but this is fine for now.
    for (int i = 0; i < 10; i++) { // Cancel up to 10 potential reminders
      final notificationId = (task.id + i.toString()).hashCode;
      await flutterLocalNotificationsPlugin.cancel(notificationId);
    }
  }
}
