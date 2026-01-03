import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/background_service.dart';
import 'ui/home_page.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyCImmVkf-piVOy_bMLNGhorv70t79XGECQ',
      appId: '1:1009802167106:android:469088ab53536c95047edb',
      messagingSenderId: '1009802167106',
      projectId: 'electromotor-task',
      storageBucket: 'electromotor-task.firebasestorage.app',
    ),
  );
  print('Handling background message: ${message.messageId}');
  
  if (message.data['action'] == 'start_tracking') {
    await BackgroundServiceManager.startService();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyCImmVkf-piVOy_bMLNGhorv70t79XGECQ',
      appId: '1:1009802167106:android:469088ab53536c95047edb',
      messagingSenderId: '1009802167106',
      projectId: 'electromotor-task',
      storageBucket: 'electromotor-task.firebasestorage.app',
    ),
  );
  
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Received foreground message: ${message.messageId}');
    if (message.data['action'] == 'start_tracking') {
      BackgroundServiceManager.startService();
    }
  });
  
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('Notification opened app: ${message.messageId}');
    if (message.data['action'] == 'start_tracking') {
      BackgroundServiceManager.startService();
    }
  });
  
  await BackgroundServiceManager.initializeService();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Location Tracking',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
