import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart'; // For debugPrint

class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  Future<void> initialize() async {
    debugPrint('✅ [LocationService] Initialized');
  }

  Future<bool> _checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

  Future<Position?> getCurrentLocation() async {
    debugPrint('Attempting to get current location...');
    if (!(await _checkConnectivity())) {
      debugPrint('No internet connectivity. Cannot fetch location.');
      return null;
    }

    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled. Requesting user to enable.');
      // Location services are not enabled don't continue
      // and ask user to enable the services.
      // Optionally, you can open location settings: Geolocator.openLocationSettings();
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      debugPrint('Location permissions are denied. Requesting permissions.');
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied (again).');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied. Cannot request permissions.');
      // Permissions are denied forever, handle appropriately.
      return null;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    debugPrint('Location permissions granted. Fetching position.');
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }
}