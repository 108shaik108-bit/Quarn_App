

import 'dart:math' as math;

import 'package:adhan/adhan.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/adhan_scheduler_service.dart';
import '../services/app_settings.dart';
import '../services/location_disclosure.dart';
import '../services/notification_service.dart';
import 'qibla_finder_screen.dart';

class PrayerTabScreen extends StatefulWidget {
  const PrayerTabScreen({super.key});

  @override
  State<PrayerTabScreen> createState() => _PrayerTabScreenState();
}

class _PrayerTabScreenState extends State<PrayerTabScreen> with WidgetsBindingObserver {
  static Color get green => AppSettings.isDark ? Color(0xFF9BD0AF) : Color(0xFF07502D);
  static Color get cream => AppSettings.isDark ? Color(0xFF101814) : Color(0xFFFFF5E2);
  static Color get gold => AppSettings.isDark ? Color(0xFFE0B96B) : Color(0xFFC49A45);

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
  bool _manualLocationSelected = false;
  bool isLoading = false;
  String? errorMessage;

  final AudioPlayer _adhanPlayer = AudioPlayer();
  String? _playingPrayer;
  bool _ringAdhanEnabled = false;
  final Map<String, bool> _prayerAdhanEnabled = {
    for (final prayer in AdhanSchedulerService.prayerNames) prayer: true,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAdhanPreferences();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshGpsLocationIfAllowed();
    }
  }

  Future<void> _loadAdhanPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCity = prefs.getString('prayer_selected_city');
    final manualLocationSelected = prefs.getBool('prayer_manual_location_selected') ?? false;
    final latitude = prefs.getDouble('prayer_location_lat');
    final longitude = prefs.getDouble('prayer_location_lon');
    final enabled = await AdhanSchedulerService.isRingEnabled();

    if (!mounted) return;
    setState(() {
      _manualLocationSelected = manualLocationSelected;
      if (latitude != null && longitude != null) {
        currentCoordinates = Coordinates(latitude, longitude);
        if (savedCity != null && savedCity.isNotEmpty) {
          selectedCity = savedCity;
          cities[savedCity] = currentCoordinates!;
          locationLabel = savedCity;
        } else {
          locationLabel = 'Saved location';
        }
        isGpsLocation = true;
      } else if (savedCity != null && cities.containsKey(savedCity)) {
        selectedCity = savedCity;
        locationLabel = '$savedCity, India';
      }
      _ringAdhanEnabled = enabled;
    });

    for (final prayer in AdhanSchedulerService.prayerNames) {
      _prayerAdhanEnabled[prayer] =
          await AdhanSchedulerService.isPrayerEnabled(prayer);
    }
    if (mounted) setState(() {});
    if (enabled) {
      await AdhanSchedulerService.refresh(
        coordinates: currentCoordinates ?? cities[selectedCity]!,
      );
    }
    await _refreshGpsLocationIfAllowed();
  }

  /// Refresh GPS automatically when permission has already been granted.
  /// A manually selected city remains selected until the user chooses GPS.
  Future<void> _refreshGpsLocationIfAllowed() async {
    if (isLoading) return;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) return;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 12),
        ),
      );
      if (!mounted) return;
      final nextCoordinates = Coordinates(position.latitude, position.longitude);
      final cityName = await _cityNameFromCoordinates(position.latitude, position.longitude);
      final previous = currentCoordinates;
      final changed = previous == null ||
          (previous.latitude - position.latitude).abs() > 0.001 ||
          (previous.longitude - position.longitude).abs() > 0.001;
      setState(() {
        currentCoordinates = nextCoordinates;
        selectedCity = cityName;
        cities[cityName] = nextCoordinates;
        isGpsLocation = true;
        _manualLocationSelected = false;
        locationLabel = cityName;
        errorMessage = null;
      });
      if (changed) await _saveLocationAndRefresh();
    } catch (_) {
      // Keep the last saved location if GPS is temporarily unavailable.
    }
  }

  Future<String> _cityNameFromCoordinates(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final locality = place.locality?.trim();
        final subLocality = place.subLocality?.trim();
        final subAdministrativeArea = place.subAdministrativeArea?.trim();
        final country = place.country?.trim();
        final city = (locality != null && locality.isNotEmpty)
            ? locality
            : (subLocality != null && subLocality.isNotEmpty)
                ? subLocality
                : (subAdministrativeArea != null && subAdministrativeArea.isNotEmpty)
                    ? subAdministrativeArea
                    : _nearestKnownCity(latitude, longitude);
        if (city != null) {
          return country == null || country.isEmpty ? city : '$city, $country';
        }
      }
    } catch (_) {
      // Use nearby known city as a fallback if Android geocoding is unavailable.
    }
    return _nearestKnownCity(latitude, longitude) ?? 'Current GPS location';
  }

  String? _nearestKnownCity(double latitude, double longitude) {
    String? nearestCity;
    double nearestDistance = double.infinity;

    for (final entry in cities.entries) {
      final cityLatitude = entry.value.latitude;
      final cityLongitude = entry.value.longitude;
      final latitudeDifference = (latitude - cityLatitude) * math.pi / 180;
      final longitudeDifference = (longitude - cityLongitude) * math.pi / 180;
      final a = math.pow(math.sin(latitudeDifference / 2), 2) +
          math.cos(latitude * math.pi / 180) *
              math.cos(cityLatitude * math.pi / 180) *
              math.pow(math.sin(longitudeDifference / 2), 2);
      final distanceKm = 6371 * 2 * math.asin(math.sqrt(a));

      if (distanceKm < nearestDistance) {
        nearestDistance = distanceKm;
        nearestCity = entry.key;
      }
    }

    // Do not label a distant, unknown location as one of our preset cities.
    return nearestDistance <= 40 ? nearestCity : null;
  }

  Future<void> _saveLocationAndRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    final coordinates = currentCoordinates ?? cities[selectedCity]!;
    await prefs.setDouble('prayer_location_lat', coordinates.latitude);
    await prefs.setDouble('prayer_location_lon', coordinates.longitude);
    await prefs.setString('prayer_selected_city', selectedCity);
    await prefs.setBool('prayer_manual_location_selected', _manualLocationSelected);
    await NotificationService.refreshPrayerTimeReminders(
      coordinates: coordinates,
    );
    if (_ringAdhanEnabled) {
      await AdhanSchedulerService.refresh(coordinates: coordinates);
    }
  }

  Future<void> _setRingAdhan(bool enabled) async {
    if (enabled) {
      try {
        await AdhanSchedulerService.requestPermissions();
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
          );
        }
        return;
      }
    }

    setState(() => _ringAdhanEnabled = enabled);
    await AdhanSchedulerService.setRingEnabled(enabled);
    if (enabled) {
      try {
        await AdhanSchedulerService.refresh(
          coordinates: currentCoordinates ?? cities[selectedCity]!,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Adhan alarms enabled for the next 7 days.')),
          );
        }
      } catch (error) {
        if (mounted) {
          await AdhanSchedulerService.cancelScheduled();
          setState(() => _ringAdhanEnabled = false);
          await AdhanSchedulerService.setRingEnabled(false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not schedule Adhan: $error')),
          );
        }
      }
    } else {
      await AdhanSchedulerService.cancelScheduled();
    }
  }

  Future<void> _setPrayerAdhan(String prayer, bool enabled) async {
    setState(() => _prayerAdhanEnabled[prayer] = enabled);
    await AdhanSchedulerService.setPrayerEnabled(prayer, enabled);
    if (_ringAdhanEnabled) {
      await AdhanSchedulerService.refresh(
        coordinates: currentCoordinates ?? cities[selectedCity]!,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _adhanPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleAdhan(String prayerName) async {
    if (_playingPrayer == prayerName) {
      await _adhanPlayer.stop();
      if (mounted) setState(() => _playingPrayer = null);
      return;
    }

    final asset = prayerName == 'Fajr'
        ? 'audio/adhan_fajr.mp3'
        : 'audio/adhan_other_prayers.mp3';

    await _adhanPlayer.stop();
    if (!mounted) return;
    setState(() => _playingPrayer = prayerName);

    try {
      await _adhanPlayer.play(AssetSource(asset));
      _adhanPlayer.onPlayerComplete.first.then((_) {
        if (mounted && _playingPrayer == prayerName) {
          setState(() => _playingPrayer = null);
        }
      });
    } catch (error) {
      if (mounted) {
        setState(() => _playingPrayer = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not play Adhan: $error')),
        );
      }
    }
  }

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
        if (!mounted) return;
        setState(() => isLoading = false);
        final openSettings = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Turn on device location'),
            content: const Text(
              'Your phone location is turned off. Please enable Location '
              'in your phone settings to use your current GPS location '
              'and calculate accurate prayer times.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Open Location Settings'),
              ),
            ],
          ),
        );
        if (openSettings == true) {
          await Geolocator.openLocationSettings();
        }
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        final consent = await LocationDisclosure.show(context);
        if (!consent) {
          if (mounted) setState(() => isLoading = false);
          return;
        }
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
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      final gpsCity = await _cityNameFromCoordinates(position.latitude, position.longitude);
      if (!mounted) return;
      final gpsCoordinates = Coordinates(position.latitude, position.longitude);
      setState(() {
        currentCoordinates = gpsCoordinates;
        selectedCity = gpsCity;
        cities[gpsCity] = gpsCoordinates;
        isGpsLocation = true;
        _manualLocationSelected = false;
        locationLabel = gpsCity;
        isLoading = false;
      });
      await _saveLocationAndRefresh();
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
      _manualLocationSelected = true;
      currentCoordinates = null;
      isGpsLocation = false;
      locationLabel = '$city, India';
      errorMessage = null;
    });
    _saveLocationAndRefresh().then((_) => _refreshGpsLocationIfAllowed());
  }

  String formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context); // Rebuild this screen when the app theme changes.
    final times = prayerTimes;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _locationCard(),
          SizedBox(height: 12),
          _qiblaFinderCard(),
          SizedBox(height: 12),
          _adhanSettingsCard(),
          SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: green,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: green.withOpacity(0.15),
                  blurRadius: 10,
                  offset: Offset(0, 4),
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
                SizedBox(height: 7),
                Text(
                  locationLabel,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 5),
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

          SizedBox(height: 18),

          if (times != null) ...[
            _prayerRow('Fajr', 'الفجر', times.fajr, Icons.nightlight_round),
            _prayerRow('Sunrise', 'الشروق', times.sunrise, Icons.wb_twilight, enableAdhan: false),
            _prayerRow('Dhuhr', 'الظهر', times.dhuhr, Icons.wb_sunny_outlined),
            _prayerRow('Asr', 'العصر', times.asr, Icons.wb_cloudy_outlined),
            _prayerRow('Maghrib', 'المغرب', times.maghrib, Icons.wb_twilight),
            _prayerRow('Isha', 'العشاء', times.isha, Icons.nights_stay_outlined),
          ],

          if (errorMessage != null) ...[
            SizedBox(height: 12),
            Text(
              errorMessage!,
              style: TextStyle(color: Colors.red),
            ),
          ],

          SizedBox(height: 12),
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



  Widget _qiblaFinderCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        final coordinates = currentCoordinates ?? cities[selectedCity]!;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => QiblaFinderScreen(
              initialLatitude: coordinates.latitude,
              initialLongitude: coordinates.longitude,
              locationLabel: locationLabel,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: AppSettings.isDark
                ? [Color(0xFF203B2D), Color(0xFF14251C)]
                : [Color(0xFF07502D), Color(0xFF0D6840)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: gold.withOpacity(0.65)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.explore_rounded, color: Color(0xFFE9D19A), size: 28),
            ),
            SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Qibla Finder',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Find the direction of the Kaaba',
                    style: TextStyle(color: Color(0xFFE9D19A), fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFE9D19A), size: 17),
          ],
        ),
      ),
    );
  }

  Widget _adhanSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color(0xFFFFFAEF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Color(0xFFF0D8A9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.volume_up_rounded, color: green),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Ring Adhan',
                  style: TextStyle(
                    color: green,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Switch(
                value: _ringAdhanEnabled,
                onChanged: _setRingAdhan,
                activeColor: green,
              ),
            ],
          ),
          Text(
            _ringAdhanEnabled
                ? 'Adhan is enabled. Choose which prayers should ring. Alarm audio may still sound in phone silent mode.'
                : 'Muted by default. Turn on Ring Adhan when you want it.',
            style: TextStyle(color: Color(0xFF52735F), fontSize: 12),
          ),
          if (_ringAdhanEnabled) ...[
            SizedBox(height: 8),
            Divider(color: Color(0xFFE9D8B8), height: 1),
            for (final prayer in AdhanSchedulerService.prayerNames)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  prayer,
                  style: TextStyle(
                    color: green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                value: _prayerAdhanEnabled[prayer] ?? true,
                activeColor: green,
                onChanged: (value) => _setPrayerAdhan(prayer, value),
              ),
          ],
        ],
      ),
    );
  }

  Widget _locationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color(0xFFFFFAEF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Color(0xFFF0D8A9)),
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
          SizedBox(height: 10),

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

          SizedBox(height: 10),

          OutlinedButton.icon(
            onPressed: isLoading ? null : useCurrentLocation,
            icon: isLoading
                ? SizedBox(
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
    IconData icon, {
    bool enableAdhan = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: Color(0xFFFFFAEF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFF0D8A9)),
      ),
      child: Row(
        children: [
          Icon(icon, color: gold, size: 24),
          SizedBox(width: 13),
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
          SizedBox(width: 15),
          Text(
            formatTime(time),
            style: TextStyle(
              color: green,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (enableAdhan) ...[
            SizedBox(width: 8),
            IconButton(
              tooltip: _playingPrayer == name ? 'Stop Adhan preview' : 'Play Adhan preview',
              onPressed: () => _toggleAdhan(name),
              icon: Icon(
                _playingPrayer == name ? Icons.stop_circle : Icons.volume_up_rounded,
                color: gold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
