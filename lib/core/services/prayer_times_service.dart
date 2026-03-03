import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';

class PrayerTimeService {
  static final PrayerTimeService _prayerTimeService =
      PrayerTimeService._internal();

  factory PrayerTimeService() {
    return _prayerTimeService;
  }
  PrayerTimeService._internal();
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    // 2. Get the position with low accuracy (high accuracy isn't needed for prayer math)
    return await Geolocator.getCurrentPosition();
  }

  PrayerTimes getTimes(double lat, double lng) {
    final coordinates = Coordinates(lat, lng);
    final params = CalculationMethod.egyptian.getParameters();
    params.madhab = Madhab.shafi;

    // Important: adhan package uses UTC internally,
    // it will match your tz.local settings automatically.
    return PrayerTimes(
        coordinates, DateComponents.from(DateTime.now()), params);
  }

  // Helper to get the next prayer for the UI countdown
  String getNextPrayerName(PrayerTimes times) {
    final next = times.nextPrayer();
    return next.name; // e.g., "fajr", "dhuhr", etc.
  }
}
