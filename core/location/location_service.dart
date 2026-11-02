import 'package:geolocator/geolocator.dart';

/// Result of a device-location request, with a user-facing error on failure.
class LocationResult {
  const LocationResult({this.position, this.error});
  final Position? position;
  final String? error;
  bool get ok => position != null;
}

class LocationService {
  /// Current device position, handling service-off + permission flow. Never
  /// throws — returns a [LocationResult] with either a position or an error
  /// message suitable to show the user.
  static Future<LocationResult> getCurrent() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult(
          error: 'Location (GPS) is turned off. Please enable it and try again.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const LocationResult(
          error: 'Location permission is needed to mark attendance.',
        );
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(
          error: 'Location permission is blocked. Please allow it in your device settings.',
        );
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return LocationResult(position: pos);
    } catch (_) {
      return const LocationResult(
        error: 'Could not read your location. Please check GPS and try again.',
      );
    }
  }
}
