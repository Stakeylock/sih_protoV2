import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sih_proto/services/database_service.dart';

class LocationService {
  StreamSubscription<Position>? _positionStream;

  Stream<Position> startTracking(String userId, DatabaseService dbService) {
    final StreamController<Position> controller = StreamController<Position>();

    _requestPermission().then((granted) {
      if (!granted) {
        debugPrint("Location permission not granted.");
        controller.close();
        return;
      }

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100, // Notify only when moved by 100 meters
      );

      _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
        (Position position) {
          debugPrint("New position: ${position.latitude}, ${position.longitude}");
          dbService.updateUserLocation(
            userId: userId,
            latitude: position.latitude,
            longitude: position.longitude,
          );
          controller.add(position); // Add position to the stream for the UI
        },
        onError: (error) {
          debugPrint("Error getting location: $error");
          controller.addError(error);
        },
      );
    });
     return controller.stream;
  }

  void stopTracking() {
    _positionStream?.cancel();
    debugPrint("Location tracking stopped.");
  }

  Future<bool> _requestPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      // The user denied the permission
      return false;
    } else if (status.isPermanentlyDenied) {
      // The user permanently denied the permission, open settings
      openAppSettings();
      return false;
    }
    return false;
  }
}

