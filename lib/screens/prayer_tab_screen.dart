

import '../services/app_settings.dart';import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class PrayerTabScreen extends StatefulWidget {
  const PrayerTabScreen({super.key});

  @override
  State<PrayerTabScreen> createState() => _PrayerTabScreenState();
}

class _PrayerTabScreenState extends State<PrayerTabScreen> {
  static const Color green = Color(0xFF07502D);
  static const Color cream = Color(0xFFFFF5E2);
  static const Color gold = Color(0xFFC49A45);

  final Map<String, Coordinates> cities = {
    'Ambattur': Coordinates(13.1143, 80.1548),
    'Chennai': Coordinates(13.0827, 80.2707),
    'Bengaluru': Coordinates(12.9716, 77.5946),
    'Hyderabad': Coordinates(17.3850, 78.4867),
    'Mumbai': Coordinates(19.0760, 72.8777),
    'Delhi': Coordinates(28.6139, 77.2090),
    'Kolkata': Coordinates(22.5726, 88.3639),
    'Kochi': Coordinates(9.9312, 76.2673),
  };

  String selectedCity = 'Ambattur';
  Coordinates? currentCoordinates;
  String locationLabel = 'Ambattur, India';
  bool isGpsLocation = false;
  bool isLoading = false;
  String? errorMessage;

  PrayerTimes? get prayerTimes {
    final coordinates = currentCoordinates ?? cities[selectedCity];

    if (coordinates == null) return null;

    final params = CalculationMethod.karachi.getParameters()
      ..madhab = Madhab.shafi;

    return PrayerTimes(
      coordinates,
      DateComponents.from(DateTime.now()),
      params,
    );
  }

  Future<void> useCurrentLocation() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception('Please turn on your device location.');
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied.');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is blocked. Enable it in app settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        currentCoordinates = Coordinates(
          position.latitude,
          position.longitude,
        );
        isGpsLocation = true;
        locationLabel = 'Current GPS location';
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  void selectCity(String? city) {
    if (city == null) return;

    setState(() {
      selectedCity = city;
      currentCoordinates = null;
      isGpsLocation = false;
      locationLabel = '$city, India';
      errorMessage = null;
    });
  }

  String formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final times = prayerTimes;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _locationCard(),
          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: green,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: green.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'DAILY PRAYER TIMES',
                  style: TextStyle(
                    color: Color(0xFFE9D19A),
                    fontSize: 12,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  locationLabel,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  MaterialLocalizations.of(context)
                      .formatMediumDate(DateTime.now()),
                  style: TextStyle(
                    color: Color(0xFFE9D19A),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          if (times != null) ...[
            _prayerRow('Fajr', 'الفجر', times.fajr, Icons.nightlight_round),
            _prayerRow('Sunrise', 'الشروق', times.sunrise, Icons.wb_twilight),
            _prayerRow('Dhuhr', 'الظهر', times.dhuhr, Icons.wb_sunny_outlined),
            _prayerRow('Asr', 'العصر', times.asr, Icons.wb_cloudy_outlined),
            _prayerRow('Maghrib', 'المغرب', times.maghrib, Icons.wb_twilight),
            _prayerRow('Isha', 'العشاء', times.isha, Icons.nights_stay_outlined),
          ],

          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              errorMessage!,
              style: TextStyle(color: Colors.red),
            ),
          ],

          const SizedBox(height: 12),
          Text(
            'Calculation: Karachi • Asr: Standard (Ahl-e-Hadith)',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF52735F),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAEF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0D8A9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Your location',
            style: TextStyle(
              color: green,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),

          DropdownButtonFormField<String>(
            value: selectedCity,
            isExpanded: true,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.location_city, color: green),
              filled: true,
              fillColor: cream,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: cities.keys.map((city) {
              return DropdownMenuItem(
                value: city,
                child: Text(city),
              );
            }).toList(),
            onChanged: selectCity,
          ),

          const SizedBox(height: 10),

          OutlinedButton.icon(
            onPressed: isLoading ? null : useCurrentLocation,
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.my_location),
            label: Text(
              isLoading ? 'Detecting location...' : 'Use my GPS location',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: green,
              side: BorderSide(color: gold),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _prayerRow(
    String name,
    String arabic,
    DateTime time,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAEF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0D8A9)),
      ),
      child: Row(
        children: [
          Icon(icon, color: gold, size: 24),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: green,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            arabic,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              color: gold,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 15),
          Text(
            formatTime(time),
            style: TextStyle(
              color: green,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
