import 'dart:async';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data/local/location_db.dart';
import '../data/remote/firestore_service.dart';
import '../services/location_service.dart';
import '../services/background_service.dart';

class TrackingController extends GetxController {
  final LocationService _locationService = LocationService();
  final FirestoreService _firestoreService = FirestoreService();
  final LocationDatabase _db = LocationDatabase.instance;
  final Connectivity _connectivity = Connectivity();

  final RxBool isTracking = false.obs;
  final Rx<Position?> currentPosition = Rx<Position?>(null);
  final RxString trackingStatus = 'Paused/Killed'.obs;
  final RxString sessionId = ''.obs;
  final RxInt locationInterval = 10.obs;

  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void onInit() {
    super.onInit();
    _initialize();
    _setupConnectivityListener();
  }

  Future<void> _initialize() async {
    try {
      await _firestoreService.signInAnonymously();
      sessionId.value = DateTime.now().millisecondsSinceEpoch.toString();
      await BackgroundServiceManager.setSessionId(sessionId.value);

      final isServiceRunning = await BackgroundServiceManager.isServiceRunning();
      if (isServiceRunning) {
        isTracking.value = true;
        trackingStatus.value = 'Tracking Active';
      }
    } catch (e) {
      print('Error initializing: $e');
    }
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        if (results.isNotEmpty && !results.contains(ConnectivityResult.none)) {
          _syncPendingLocations();
        }
      },
    );
  }

  Future<void> startTracking() async {
    try {
      final hasPermission = await _locationService.checkPermission();
      if (!hasPermission) {
        await _locationService.requestPermissions();
        return;
      }

      isTracking.value = true;
      trackingStatus.value = 'Tracking Active';
      sessionId.value = DateTime.now().millisecondsSinceEpoch.toString();
      await BackgroundServiceManager.setSessionId(sessionId.value);
      await BackgroundServiceManager.setLocationInterval(locationInterval.value);
      await BackgroundServiceManager.startService();

      _startForegroundTracking();
      await _syncPendingLocations();
    } catch (e) {
      print('Error starting tracking: $e');
      trackingStatus.value = 'Error: $e';
    }
  }

  Future<void> stopTracking() async {
    try {
      isTracking.value = false;
      trackingStatus.value = 'Paused/Killed';
      await BackgroundServiceManager.stopService();
      _stopForegroundTracking();
    } catch (e) {
      print('Error stopping tracking: $e');
    }
  }

  void _startForegroundTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = _locationService
        .getLocationStream(interval: Duration(seconds: locationInterval.value))
        ?.listen(
      (position) {
        currentPosition.value = position;
        _saveLocation(position);
      },
      onError: (error) {
        print('Location stream error: $error');
        getCurrentLocation();
      },
      onDone: () {
        print('Location stream closed');
      },
    );
  }

  void _stopForegroundTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  Future<void> _saveLocation(Position position) async {
    try {
      final locationModel = _locationService.positionToLocationModel(
        position,
        sessionId.value,
      );

      if (locationModel != null) {
        await _db.insert(locationModel);
        await _syncPendingLocations();
      }
    } catch (e) {
      print('Error saving location: $e');
    }
  }

  Future<void> _syncPendingLocations() async {
    try {
      final unsyncedLocations = await _db.getUnsyncedLocations();
      if (unsyncedLocations.isEmpty) return;

      await _firestoreService.uploadBatchLocations(unsyncedLocations);
      final syncedIds = unsyncedLocations.map((loc) => loc.id).toList();
      await _db.markAsSynced(syncedIds);
    } catch (e) {
      print('Error syncing locations: $e');
    }
  }

  Future<void> getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        currentPosition.value = position;
      }
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  void updateLocationInterval(int seconds) {
    locationInterval.value = seconds;
    BackgroundServiceManager.setLocationInterval(seconds);
  }

  @override
  void onClose() {
    _locationSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _locationService.dispose();
    super.onClose();
  }
}

