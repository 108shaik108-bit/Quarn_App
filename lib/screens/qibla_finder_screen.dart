import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

import '../services/app_settings.dart';
import '../services/location_disclosure.dart';
import '../services/qibla_direction_service.dart';

class QiblaFinderScreen extends StatefulWidget {
  const QiblaFinderScreen({
    super.key,
    required this.initialLatitude,
    required this.initialLongitude,
    required this.locationLabel,
  });

  final double initialLatitude;
  final double initialLongitude;
  final String locationLabel;

  @override
  State<QiblaFinderScreen> createState() => _QiblaFinderScreenState();
}

class _QiblaFinderScreenState extends State<QiblaFinderScreen> {
  double? _heading;
  double? _accuracy;
  late double _latitude;
  late double _longitude;
  late String _locationLabel;
  bool _isLoadingLocation = false;
  String? _locationError;
  StreamSubscription<CompassEvent>? _compassSubscription;

  bool get _isDark => AppSettings.isDark;
  Color get _background => _isDark ? const Color(0xFF101814) : const Color(0xFFFFF5E2);
  Color get _surface => _isDark ? const Color(0xFF19251F) : const Color(0xFFFFFAEF);
  Color get _green => _isDark ? const Color(0xFF9BD0AF) : const Color(0xFF07502D);
  Color get _gold => _isDark ? const Color(0xFFE0B96B) : const Color(0xFFC49A45);
  Color get _muted => _isDark ? const Color(0xFFB5C4BA) : const Color(0xFF52735F);

  double get _qiblaBearing =>
      QiblaDirectionService.bearingFrom(_latitude, _longitude);

  double get _distanceKm =>
      QiblaDirectionService.distanceKmFrom(_latitude, _longitude);

  @override
  void initState() {
    super.initState();
    _latitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;
    _locationLabel = widget.locationLabel;
    _listenToCompass();
  }

  void _listenToCompass() {
    _compassSubscription = FlutterCompass.events?.listen(
      (event) {
        if (!mounted) return;
        setState(() {
          _heading = event.heading;
          _accuracy = event.accuracy;
        });
      },
      onError: (_) {
        if (mounted) setState(() => _heading = null);
      },
    );
  }

  Future<void> _refreshLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Turn on location services to update your Qibla location.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final consent = await LocationDisclosure.show(context);
        if (!consent) {
          if (mounted) setState(() => _isLoadingLocation = false);
          return;
        }
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is needed to update your Qibla direction.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationLabel = 'Current GPS location';
        _isLoadingLocation = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _locationError = error.toString().replaceFirst('Exception: ', '');
        _isLoadingLocation = false;
      });
    }
  }

  String _directionName(double degrees) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return directions[((degrees + 22.5) ~/ 45) % 8];
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heading = _heading;
    final relativeBearing = heading == null ? _qiblaBearing : (_qiblaBearing - heading + 360) % 360;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Qibla Finder'),
        backgroundColor: _background,
        foregroundColor: _green,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            children: [
              Text(
                'FIND THE DIRECTION OF THE KAABA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _muted,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              _buildCompass(relativeBearing, heading != null),
              const SizedBox(height: 22),
              Text(
                '${_qiblaBearing.toStringAsFixed(1)}°  ${_directionName(_qiblaBearing)}',
                style: TextStyle(
                  color: _green,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Qibla bearing from true north',
                style: TextStyle(color: _muted, fontSize: 13),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(child: _infoTile('DISTANCE TO KAABA', '${_distanceKm.toStringAsFixed(0)} km', Icons.straighten_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: _infoTile('PHONE HEADING', heading == null ? 'Unavailable' : '${heading.toStringAsFixed(0)}°', Icons.explore_rounded)),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _gold.withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: _gold),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your location', style: TextStyle(color: _muted, fontSize: 12)),
                          const SizedBox(height: 3),
                          Text(_locationLabel, style: TextStyle(color: _green, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh location',
                      onPressed: _isLoadingLocation ? null : _refreshLocation,
                      icon: _isLoadingLocation
                          ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _green))
                          : Icon(Icons.my_location_rounded, color: _green),
                    ),
                  ],
                ),
              ),
              if (_locationError != null) ...[
                const SizedBox(height: 8),
                Text(_locationError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.screen_rotation_alt_rounded, color: _gold),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            heading == null ? 'Compass sensor unavailable' : 'For a more accurate direction',
                            style: TextStyle(color: _green, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            heading == null
                                ? 'The compass is available on supported phones. You can still use the Qibla bearing shown above.'
                                : 'Keep your phone flat and move it in a figure-eight motion if the compass seems inaccurate. Move away from magnets and metal objects.',
                            style: TextStyle(color: _muted, fontSize: 12, height: 1.45),
                          ),
                          if (_accuracy != null) ...[
                            const SizedBox(height: 5),
                            Text('Sensor accuracy: ±${_accuracy!.toStringAsFixed(0)}°', style: TextStyle(color: _muted, fontSize: 11)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompass(double relativeBearing, bool hasHeading) {
    return SizedBox(
      width: 290,
      height: 290,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _surface,
          border: Border.all(color: _gold.withOpacity(0.65), width: 2),
          boxShadow: [
            BoxShadow(
              color: _green.withOpacity(0.08),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _gold.withOpacity(0.35), width: 1),
              ),
            ),
            Positioned(top: 18, child: Text('N', style: TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 15))),
            Positioned(bottom: 18, child: Text('S', style: TextStyle(color: _muted, fontWeight: FontWeight.w600))),
            Positioned(left: 20, child: Text('W', style: TextStyle(color: _muted, fontWeight: FontWeight.w600))),
            Positioned(right: 20, child: Text('E', style: TextStyle(color: _muted, fontWeight: FontWeight.w600))),
            for (int i = 0; i < 60; i++)
              Transform.rotate(
                angle: i * math.pi / 30,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.only(top: 7),
                    width: i % 5 == 0 ? 2 : 1,
                    height: i % 5 == 0 ? 11 : 6,
                    color: _gold.withOpacity(i % 5 == 0 ? 0.9 : 0.4),
                  ),
                ),
              ),
            Transform.rotate(
              angle: relativeBearing * math.pi / 180,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.navigation_rounded, size: 92, color: _green),
                  Container(
                    width: 8,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _gold,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                color: _gold,
                shape: BoxShape.circle,
                border: Border.all(color: _surface, width: 3),
              ),
            ),
            Positioned(
              bottom: 55,
              child: Text(
                hasHeading ? 'TURN TO ALIGN' : 'QIBLA DIRECTION',
                style: TextStyle(color: _muted, fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: _gold, size: 21),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(value, textAlign: TextAlign.center, style: TextStyle(color: _green, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
