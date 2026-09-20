import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/emergency_notification_model.dart';
import '../../models/incident_model.dart';
import '../../models/inspection_model.dart';

class EmergencyNotificationService {
  static final EmergencyNotificationService instance =
      EmergencyNotificationService._internal();

  EmergencyNotificationService._internal();

  static const String _storageKey = 'minova_emergency_notifications_v1';
  final _notificationsController =
      StreamController<List<EmergencyNotificationModel>>.broadcast();

  List<EmergencyNotificationModel> _cachedList = [];
  bool _isInitialized = false;

  Stream<List<EmergencyNotificationModel>> get notificationsStream =>
      _notificationsController.stream;

  List<EmergencyNotificationModel> get currentNotifications =>
      List.unmodifiable(_cachedList);

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw) as List;
        _cachedList = decoded
            .map((e) =>
                EmergencyNotificationModel.fromMap(e as Map<String, dynamic>))
            .toList();
      } else {
        // Seed initial situational broadcast for field responder onboarding
        _cachedList = _getSeedNotifications();
        await _saveToDisk();
      }
      _cachedList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _notificationsController.add(_cachedList);
      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[EMG_NOTIF] Init error: $e');
      }
    }
  }

  Future<void> addNotification(EmergencyNotificationModel item) async {
    // Deduplication check
    final index = _cachedList.indexWhere((n) => n.id == item.id);
    if (index >= 0) {
      _cachedList[index] = item;
    } else {
      _cachedList.insert(0, item);
    }
    _cachedList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _notificationsController.add(_cachedList);
    await _saveToDisk();
  }

  Future<void> markAsRead(String id) async {
    final index = _cachedList.indexWhere((n) => n.id == id);
    if (index >= 0) {
      _cachedList[index] = _cachedList[index].copyWith(isRead: true);
      _notificationsController.add(_cachedList);
      await _saveToDisk();
    }
  }

  int get unreadCount => _cachedList.where((n) => !n.isRead).length;

  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapped = _cachedList.map((n) => n.toMap()).toList();
      await prefs.setString(_storageKey, jsonEncode(mapped));
    } catch (_) {}
  }

  List<EmergencyNotificationModel> _getSeedNotifications() {
    final now = DateTime.now();
    return [
      EmergencyNotificationModel(
        id: 'EMG-FIRE-001',
        incidentType: IncidentType.fire,
        severity: ViolationSeverity.critical,
        title: '🚨 CRITICAL: Underground Fire Alert',
        description:
            'Localized smoldering detected near Substation Switchgear Panel-4 in Seam 3 Face. Smoke density rising.',
        mineId: 'JH-DHA-BCCL-007',
        locationDisplay: 'Underground Workshop — Panel 4 (Seam 3 Face)',
        latitude: 23.7957,
        longitude: 86.4304,
        createdAt: now.subtract(const Duration(minutes: 12)),
        targetSpecialist: 'mechanical',
        instructions:
            'Proceed to affected area with self-rescuer and Class-B/C suppression gear. Isolate electrical feed immediately.',
        isRead: false,
      ),
      EmergencyNotificationModel(
        id: 'EMG-GAS-002',
        incidentType: IncidentType.gasLeak,
        severity: ViolationSeverity.major,
        title: '⚠️ Methane Influx (CH4 > 1.25%)',
        description:
            'Continuous telemetry sensor detected rising methane concentrations in Gallery 4 return airway.',
        mineId: 'JH-DHA-BCCL-007',
        locationDisplay: 'Return Airway Gallery 4 East',
        latitude: 23.7962,
        longitude: 86.4312,
        createdAt: now.subtract(const Duration(hours: 2)),
        targetSpecialist: 'ventilation',
        instructions:
            'Inspect auxiliary fan ventilation ducting and verify flameproof seals.',
        isRead: true,
      ),
      EmergencyNotificationModel(
        id: 'EMG-HEMM-003',
        incidentType: IncidentType.equipmentFailure,
        severity: ViolationSeverity.major,
        title: '⚠️ Continuous Miner Hydraulic Rupture',
        description:
            'High-pressure hydraulic hose failure on CM-04 loader boom. Oil spill on conveyor line.',
        mineId: 'JH-DHA-BCCL-007',
        locationDisplay: 'Depillaring Section 2 (North Face)',
        latitude: 23.7948,
        longitude: 86.4295,
        createdAt: now.subtract(const Duration(hours: 5)),
        targetSpecialist: 'mechanical',
        instructions:
            'Mechanical responders deploy spill containment kit and replace SAE 100R2 hose assembly.',
        isRead: true,
      ),
    ];
  }
}
