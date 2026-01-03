import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import '../data/local/location_db.dart';
import '../data/remote/firestore_service.dart';
import '../data/models/location_model.dart';
import 'location_service.dart';

class BackgroundServiceManager {
  static const String _locationIntervalKey = 'location_interval';
  static const String _sessionIdKey = 'session_id';

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: false,
        notificationChannelId: 'location_tracking',
        initialNotificationTitle: 'Location Tracking',
        initialNotificationContent: 'Tracking your location in background',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyCImmVkf-piVOy_bMLNGhorv70t79XGECQ',
          appId: '1:1009802167106:android:469088ab53536c95047edb',
          messagingSenderId: '1009802167106',
          projectId: 'electromotor-task',
          storageBucket: 'electromotor-task.firebasestorage.app',
        ),
      );
    } catch (e) {
      print('Firebase initialization in background: $e');
    }

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        try {
          service.setForegroundNotificationInfo(
            title: "Location Tracking",
            content: "Tracking your location in background",
          );
          service.setAsForegroundService();
        } catch (e) {
          print('Error in setAsForeground: $e');
        }
      });

      service.on('setAsBackground').listen((event) {
        try {
          service.setAsBackgroundService();
        } catch (e) {
          print('Error in setAsBackground: $e');
        }
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    Timer.periodic(const Duration(seconds: 1), (timer) async {
      await _trackLocation(service);
    });
  }

  static Future<void> _trackLocation(ServiceInstance service) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final interval = prefs.getInt(_locationIntervalKey) ?? 10;
      final lastTrackTime = prefs.getInt('last_track_time') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (now - lastTrackTime < (interval * 1000)) {
        return;
      }

      final locationService = LocationService();
      final hasPermission = await locationService.checkPermission();

      if (!hasPermission) {
        service.invoke('permission_denied');
        return;
      }

      final position = await locationService.getCurrentLocation();

      if (position != null) {
        final sessionId = prefs.getString(_sessionIdKey) ?? 
            DateTime.now().millisecondsSinceEpoch.toString();
        
        final locationModel = LocationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: position.timestamp,
          sessionId: sessionId,
        );

        final db = LocationDatabase.instance;
        await db.insert(locationModel);

        await prefs.setInt('last_track_time', now);

        service.invoke('location_update', {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': locationModel.timestamp.toIso8601String(),
        });

        await _syncLocationsToFirestore();
      }
    } catch (e) {
      print('Error in background location tracking: $e');
    }
  }

  static Future<void> _syncLocationsToFirestore() async {
    try {
      final db = LocationDatabase.instance;
      final unsyncedLocations = await db.getUnsyncedLocations();

      if (unsyncedLocations.isEmpty) return;

      final firestoreService = FirestoreService();

      try {
        await firestoreService.uploadBatchLocations(unsyncedLocations);
        final syncedIds = unsyncedLocations.map((loc) => loc.id).toList();
        await db.markAsSynced(syncedIds);
      } catch (e) {
        print('Failed to sync locations: $e');
      }
    } catch (e) {
      print('Error syncing locations: $e');
    }
  }

  static Future<void> startService() async {
    try {
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();
      if (!isRunning) {
        await service.startService();
      }
    } catch (e) {
      print('Error starting background service: $e');
    }
  }

  static Future<void> stopService() async {
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    if (isRunning) {
      service.invoke('stopService');
    }
  }

  static Future<bool> isServiceRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }

  static Future<void> setLocationInterval(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_locationIntervalKey, seconds);
  }

  static Future<void> setSessionId(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionIdKey, sessionId);
  }
}

