import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as perm;

class LocationService {
  static final LocationService _instance = LocationService._internal();
  final Location _location = Location();
  bool _serviceEnabled = false;
  PermissionStatus? _permissionGranted;

  // Singleton pattern
  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  Future<bool> initializeLocationService() async {
    // Check if location service is enabled
    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) {
        return false;
      }
    }

    // Request permission
    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return false;
      }
    }

    // Enable background mode and high accuracy
    await _location.enableBackgroundMode(enable: true);
    await _location.changeSettings(accuracy: LocationAccuracy.high);

    return true;
  }

  Future<LocationData?> getCurrentLocation() async {
    try {
      if (!_serviceEnabled || _permissionGranted != PermissionStatus.granted) {
        bool initialized = await initializeLocationService();
        if (!initialized) {
          return null;
        }
      }

      return await _location.getLocation();
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }
}