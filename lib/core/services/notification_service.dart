import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Mexico_City'));

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
        
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  static Future<void> scheduleStreakReminder() async {
    await _notificationsPlugin.cancelAll();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20); 
    scheduledDate = scheduledDate.add(const Duration(days: 1));

    // --- MODO DE PRUEBA (10 segundos) ---
    scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'streak_channel', 
      'Recordatorios de Racha',
      channelDescription: 'Avisa cuando tu racha de estudio está en peligro',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF009688), // Color Teal
    );

    const NotificationDetails platformSpecifics = NotificationDetails(android: androidDetails);

    // En v17, zonedSchedule exige este parámetro para interpretar la fecha
    await _notificationsPlugin.zonedSchedule(
      0, // id
      '¡Tu racha está en peligro! 🔥', // title
      'Aún no has estudiado hoy. Entra a StudyQuest y completa una lección rápida.', // body
      scheduledDate, // fecha
      platformSpecifics, // detalles
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, 
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime, // <--- LA PIEZA QUE FALTABA
    );
    
    print("⏰ Megáfono listo: Notificación programada para $scheduledDate");
  }
}