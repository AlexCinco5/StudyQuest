// Importamos Flutter para poder usar colores (como el Color Teal que usamos mas abajo).
import 'package:flutter/material.dart';

// Este paquete es el motor principal para crear y enviar notificaciones locales 
// (notificaciones que crea el mismo telefono, sin necesidad de internet ni servidores).
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Estos dos paquetes (timezone) sirven para que la aplicacion entienda las zonas horarias.
// Sin esto, la app no sabria a que hora exacta mandar la notificacion si viajas a otro pais.
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Creamos una clase servicio. Su unico trabajo en la vida es manejar las notificaciones.
class NotificationService {
  
  // Creamos el "enchufe" o controlador principal de las notificaciones. 
  // 'static' significa que solo hay un controlador en toda la aplicacion para no hacer duplicados.
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  // Esta funcion enciende el motor de notificaciones. Debe llamarse cuando la app arranca.
  static Future<void> init() async {
    
    // Primero, le enseñamos al reloj de la app todas las zonas horarias del mundo.
    tz.initializeTimeZones();
    // Luego, le decimos: "Nosotros estamos en la hora de Ciudad de Mexico".
    tz.setLocalLocation(tz.getLocation('America/Mexico_City'));

    // Configuramos como se vera el icono de la notificacion en Android. 
    // Usamos el icono por defecto de la app ('@mipmap/ic_launcher').
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Configuramos los permisos para los iPhone (iOS). 
    // Le pedimos permiso para hacer ruido, poner el puntito rojo en el icono (badge) y mostrar alertas.
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    // Empaquetamos las configuraciones de Android y iOS juntas.
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Finalmente, prendemos el motor con las configuraciones que armamos.
    await _notificationsPlugin.initialize(initSettings);

    // En los Android modernos, necesitamos pedirle permiso explicito al usuario 
    // para poder enviarle notificaciones (saldra un cuadrito preguntando "Permitir?").
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
        
    // Tambien le pedimos permiso especial para poner alarmas exactas (para que la notificacion suene justo a tiempo).
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  // Esta funcion es la encargada de programar la alarma que te recordara estudiar para no perder tu racha.
  static Future<void> scheduleStreakReminder() async {
    
    // Si ya habia alarmas viejas programadas, las borramos para no volver loco al usuario con mensajes repetidos.
    await _notificationsPlugin.cancelAll();

    // Vemos que hora es ahorita mismo.
    final now = tz.TZDateTime.now(tz.local);
    
    // Programamos la fecha inicial para hoy a las 8:00 PM (20 hrs).
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20); 
    
    // Le sumamos 1 dia para que la alarma suene hasta MAÑANA a las 8:00 PM si no has estudiado.
    scheduledDate = scheduledDate.add(const Duration(days: 1));

    // --- MODO DE PRUEBA (10 segundos) ---
    // (Esta linea esta sobreescribiendo la fecha de arriba solo para hacer pruebas rapidas 
    // y que la alarma suene 10 segundos despues de llamar a esta funcion).
    scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));

    // Configuramos el diseño de la tarjetita de notificacion para Android.
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'streak_channel', // Un ID interno para agrupar notificaciones del mismo tipo
      'Recordatorios de Racha', // El nombre que el usuario vera en los ajustes de su telefono
      channelDescription: 'Avisa cuando tu racha de estudio está en peligro', // Explicacion para el usuario
      importance: Importance.max, // Queremos que salga hasta arriba y llame la atencion
      priority: Priority.high,    // Prioridad maxima para que no se quede escondida
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF009688), // Le ponemos el color "Teal" tipico de la app
    );

    // Empaquetamos los detalles especificos (en este caso, solo los de Android).
    const NotificationDetails platformSpecifics = NotificationDetails(android: androidDetails);

    // Esta es la orden final. Le decimos al reloj interno del telefono: 
    // "Despiertame a esta hora exacta y pon este titulo y mensaje en pantalla".
    await _notificationsPlugin.zonedSchedule(
      0, // Numero de identificacion de la alarma
      '¡Tu racha está en peligro! 🔥', // Titulo en negritas
      'Aún no has estudiado hoy. Entra a StudyQuest y completa una lección rápida.', // Texto secundario
      scheduledDate, // La hora exacta que calculamos arriba
      platformSpecifics, // El diseño de la tarjetita que creamos
      
      // Permitimos que la alarma suene incluso si el telefono esta bloqueado e inactivo (idle)
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, 
      
      // Le explicamos al telefono como interpretar el formato de hora que le dimos
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime, 
    );
    
    // Un simple mensaje en consola para los desarrolladores confirmando que la alarma quedo puesta.
    print("⏰ Megáfono listo: Notificación programada para $scheduledDate");
  }
}