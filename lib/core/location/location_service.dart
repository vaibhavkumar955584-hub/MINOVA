import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/mine_model.dart';

class LocationResult {
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String locationSource; // 'gps' | 'gps_low' | 'manual'
  final String? zoneId;
  final String? zoneName;
  final String depthLevel;
  final bool isMocked;
  final DateTime timestamp;

  LocationResult({
    this.latitude,
    this.longitude,
    this.accuracy,
    required this.locationSource,
    this.zoneId,
    this.zoneName,
    this.depthLevel = 'SURFACE',
    this.isMocked = false,
    required this.timestamp,
  });

  String get displayTag {
    if (locationSource == 'manual' && zoneName != null) {
      return '$zoneName ($depthLevel)';
    }
    if (latitude != null && longitude != null) {
      return '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)} ($locationSource)';
    }
    return zoneName ?? 'Unknown Mine Zone';
  }
}

class LocationService {
  static final LocationService instance = LocationService._init();
  LocationService._init();

  List<MineZone> get cachedZones => MineModel.defaultZones;

  Future<LocationResult> captureLocation({
    Duration timeout = const Duration(seconds: 4),
    MineZone? manualFallbackZone,
  }) async {
    try {
      if (kIsWeb) {
        return _fallbackToManual(manualFallbackZone);
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _fallbackToManual(manualFallbackZone);
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return _fallbackToManual(manualFallbackZone);
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(timeout);

      final accuracy = position.accuracy;
      final isLow = accuracy > 25.0;

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: accuracy,
        locationSource: isLow ? 'gps_low' : 'gps',
        depthLevel: 'SURFACE',
        isMocked: position.isMocked,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      // Timeout or underground rock strata blocking satellite signals
      return _fallbackToManual(manualFallbackZone);
    }
  }

  LocationResult _fallbackToManual(MineZone? zone) {
    final selected = zone ?? MineModel.defaultZones[1]; // default: Seam 3 - Gallery 4
    return LocationResult(
      locationSource: 'manual',
      zoneId: selected.id,
      zoneName: selected.name,
      depthLevel: selected.depthLevel,
      isMocked: false,
      timestamp: DateTime.now(),
    );
  }
}
