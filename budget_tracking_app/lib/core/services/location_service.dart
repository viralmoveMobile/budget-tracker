import 'package:geocoding/geocoding.dart' as geo;
import 'package:location/location.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  /// Determine the current position of the device.
  Future<LocationData?> _determinePosition() async {
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return null;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return null;
      }
    }

    return await location.getLocation();
  }

  /// Get the ISO country code for the current user location
  Future<String?> getUserCountryCode() async {
    try {
      final position = await _determinePosition();
      if (position == null) return null;

      if (position.latitude != null && position.longitude != null) {
        List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
          position.latitude!,
          position.longitude!,
        );

        if (placemarks.isNotEmpty) {
          return placemarks.first.isoCountryCode;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }
}
