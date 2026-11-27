import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/date_symbol_data_local.dart'; 
import 'firebase_options.dart';

import 'package:get/get.dart';
import 'app/routes/app_pages.dart'; 
import 'app/modules/home/controllers/home_controller.dart';
import 'app/translations/app_translations.dart';

List<List<dynamic>> riwayatCSV = [
  ["Client Timestamp (Phone)", "Received At (Epoch)", "Firebase Timestamp", "Temperature (C)", "Humidity (%)", "Nutrient (PPM)", "pH"]
];

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    debugPrint(" [BACKGROUND] Critical alert: ${message.notification?.title}");
  }
}

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'growsense_channel', 
  'GrowSense Alert', 
  description: 'Channel for critical plant notifications',
  importance: Importance.max,
  sound: RawResourceAndroidNotificationSound('suara_growsense'), 
  playSound: true,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await initializeDateFormatting('id_ID', null);
  await initializeDateFormatting('en_US', null);

  pantauDataSensorTanpaUI();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true, 
    badge: true, 
    sound: true,
    criticalAlert: true,
  );
  await messaging.subscribeToTopic('growsense_peringatan');

  if (kDebugMode) {
    debugPrint(" App successfully subscribed to growsense_peringatan channel!");
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      String titleText = notification.title ?? "GrowSense Alert";
      String bodyText = notification.body ?? "";

      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        titleText,
        bodyText,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: '@mipmap/ic_launcher',
            sound: const RawResourceAndroidNotificationSound('suara_growsense'),
            playSound: true,
            importance: Importance.max,
            priority: Priority.max,
            fullScreenIntent: true,
            styleInformation: BigTextStyleInformation(
              bodyText,
              contentTitle: titleText,
              htmlFormatBigText: true,
              htmlFormatContentTitle: true,
            ),
          ),
        ),
      );
    }
  });

  Get.put(HomeController(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'GrowSense',
      debugShowCheckedModeBanner: false,
      translations: AppTranslations(),
      locale: const Locale('id', 'ID'), // Default Bahasa Indonesia (bisa diubah ke en_US)
      fallbackLocale: const Locale('en', 'US'),
      initialRoute: AppPages.initial, 
      getPages: AppPages.routes,      
    );
  }
}

void pantauDataSensorTanpaUI() {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();

  dbRef.child('sensor_tanaman').onValue.listen((DatabaseEvent event) async {
    final data = event.snapshot.value;

    if (data != null && data is Map) {
      DateTime waktuHp = DateTime.now();
      
      String clientTimestampLengkap = "${waktuHp.year}-${waktuHp.month.toString().padLeft(2, '0')}-${waktuHp.day.toString().padLeft(2, '0')} "
                                     "${waktuHp.hour.toString().padLeft(2, '0')}:${waktuHp.minute.toString().padLeft(2, '0')}:${waktuHp.second.toString().padLeft(2, '0')}";
      int receivedAtEpoch = waktuHp.millisecondsSinceEpoch;

      var suhu = data['suhu'] ?? 0;
      var kelembapan = data['kelembapan'] ?? 0;
      var nutrisi = data['nutrisi'] ?? 0;
      var ph = data['ph'] ?? 0;
      var timestampFirebase = data['timestamp_server'] ?? 'No TS Gateway';

      try {
        final Directory? dir = await getExternalStorageDirectory(); 
        final File file = File("${dir?.path}/log_growsense_v2.csv");

        if (!await file.exists()) {
          String headerCsv = const ListToCsvConverter().convert([
            [
              "Client Timestamp (Phone)", 
              "Received At (Epoch)", 
              "Firebase Timestamp", 
              "Temperature (C)", 
              "Humidity (%)", 
              "Nutrient (PPM)", 
              "pH"
            ]
          ]);
          await file.writeAsString("$headerCsv\n");
        }

        List<dynamic> barisBaru = [
          clientTimestampLengkap,
          receivedAtEpoch,
          timestampFirebase,
          suhu,
          kelembapan,
          nutrisi,
          ph
        ];

        String csvBarisBaru = const ListToCsvConverter().convert([barisBaru]);
        await file.writeAsString("$csvBarisBaru\n", mode: FileMode.append);

      } catch (e) {
        if (kDebugMode) debugPrint(" Failed to save local CSV: $e");
      }
    }
  });
}