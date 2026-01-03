import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/models/location_model.dart';

class LocationService {
  Stream<Position>? _positionStream;
  Position? _lastPosition;

  Position? get lastPosition => _lastPosition;

  Future<bool> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentLocation() async {
    try {
      bool hasPermission = await checkPermission();
      if (!hasPermission) {
        print('Location permission not granted');
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('Location request timed out');
          throw TimeoutException('Location request timed out', const Duration(seconds: 15));
        },
      );

      _lastPosition = position;
      return position;
    } on TimeoutException {
      print('Location request timed out - check GPS is enabled');
      return null;
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  Stream<Position>? getLocationStream({
    Duration interval = const Duration(seconds: 10),
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) {
    try {
      _positionStream = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          distanceFilter: 10,
          timeLimit: null,
        ),
      );
      return _positionStream?.timeout(
        Duration(seconds: interval.inSeconds * 2),
        onTimeout: (sink) {
          print('Location stream timeout - no position received in ${interval.inSeconds * 2} seconds');
          sink.close();
        },
      );
    } catch (e) {
      print('Error getting location stream: $e');
      return null;
    }
  }

  LocationModel? positionToLocationModel(Position position, String sessionId) {
    if (position.latitude == 0 && position.longitude == 0) {
      return null;
    }

    return LocationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: position.timestamp,
      sessionId: sessionId,
    );
  }

  Future<void> requestPermissions() async {
    await Permission.location.request();
    await Permission.locationWhenInUse.request();
    await Permission.locationAlways.request();
  }

  void dispose() {
    _positionStream = null;
    _lastPosition = null;
  }
}

