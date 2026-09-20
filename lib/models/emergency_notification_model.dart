import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'incident_model.dart';
import 'inspection_model.dart';

/// Represents an emergency broadcast notification sent from Mine Management.
class EmergencyNotificationModel {
  final String id;
  final IncidentType incidentType;
  final ViolationSeverity severity;
  final String title;
  final String description;
  final String mineId;
  final String locationDisplay;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final String targetSpecialist;
  final String instructions;
  final String? deepLink;
  final bool isRead;

  EmergencyNotificationModel({
    required this.id,
    required this.incidentType,
    required this.severity,
    required this.title,
    required this.description,
    required this.mineId,
    required this.locationDisplay,
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.targetSpecialist = 'all',
    required this.instructions,
    this.deepLink,
    this.isRead = false,
  });

  EmergencyNotificationModel copyWith({
    String? id,
    IncidentType? incidentType,
    ViolationSeverity? severity,
    String? title,
    String? description,
    String? mineId,
    String? locationDisplay,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    String? targetSpecialist,
    String? instructions,
    String? deepLink,
    bool? isRead,
  }) {
    return EmergencyNotificationModel(
      id: id ?? this.id,
      incidentType: incidentType ?? this.incidentType,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      description: description ?? this.description,
      mineId: mineId ?? this.mineId,
      locationDisplay: locationDisplay ?? this.locationDisplay,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      targetSpecialist: targetSpecialist ?? this.targetSpecialist,
      instructions: instructions ?? this.instructions,
      deepLink: deepLink ?? this.deepLink,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'incident_type': incidentType.value,
      'severity': severity.name,
      'title': title,
      'description': description,
      'mine_id': mineId,
      'location_display': locationDisplay,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
      'target_specialist': targetSpecialist,
      'instructions': instructions,
      'deep_link': deepLink,
      'is_read': isRead ? 1 : 0,
    };
  }

  factory EmergencyNotificationModel.fromMap(Map<String, dynamic> map) {
    return EmergencyNotificationModel(
      id: map['id']?.toString() ?? 'EMG-${DateTime.now().millisecondsSinceEpoch}',
      incidentType: IncidentTypeExtension.fromString(
        map['incident_type']?.toString() ?? 'other',
      ),
      severity: ViolationSeverity.values.firstWhere(
        (e) => e.name.toLowerCase() == (map['severity']?.toString().toLowerCase() ?? ''),
        orElse: () => ViolationSeverity.critical,
      ),
      title: map['title']?.toString() ?? 'EMERGENCY ALERT',
      description: map['description']?.toString() ?? '',
      mineId: map['mine_id']?.toString() ?? '',
      locationDisplay: map['location_display']?.toString() ?? 'Underground Mine',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      targetSpecialist: map['target_specialist']?.toString() ?? 'all',
      instructions: map['instructions']?.toString() ?? 'Proceed with caution.',
      deepLink: map['deep_link']?.toString(),
      isRead: map['is_read'] == 1 || map['is_read'] == true,
    );
  }

  factory EmergencyNotificationModel.fromRemoteMessage(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;

    final id = (data['notification_id'] ??
            data['id'] ??
            data['event_id'] ??
            message.messageId ??
            'EMG-${DateTime.now().millisecondsSinceEpoch}')
        .toString();

    final rawType = (data['incident_type'] ??
            data['emergency_type'] ??
            data['type'] ??
            'other')
        .toString();

    final rawSeverity = (data['severity'] ??
            data['priority'] ??
            'critical')
        .toString()
        .toLowerCase();

    final title = notification?.title ??
        (data['title'] ?? '🚨 EMERGENCY BROADCAST').toString();

    final body = notification?.body ??
        (data['body'] ??
                data['description'] ??
                data['short_description'] ??
                'Emergency incident reported in mine sector.')
            .toString();

    final mineId = (data['mine_id'] ?? data['mine'] ?? '').toString();
    final locationDisplay = (data['location_display'] ??
            data['location'] ??
            data['zone_name'] ??
            'Underground Mine Sector')
        .toString();

    final instructions = (data['instructions'] ??
            data['response_instruction'] ??
            'Proceed to affected area with safety equipment.')
        .toString();

    final targetSpecialist = (data['target_specialist'] ??
            data['specialist'] ??
            data['target'] ??
            'all')
        .toString();

    double? lat;
    double? lng;
    if (data['latitude'] != null) {
      lat = double.tryParse(data['latitude'].toString());
    }
    if (data['longitude'] != null) {
      lng = double.tryParse(data['longitude'].toString());
    }

    DateTime created = DateTime.now();
    if (data['created_at'] != null || data['timestamp'] != null) {
      final rawDate = (data['created_at'] ?? data['timestamp']).toString();
      created = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else if (message.sentTime != null) {
      created = message.sentTime!;
    }

    return EmergencyNotificationModel(
      id: id,
      incidentType: IncidentTypeExtension.fromString(rawType),
      severity: ViolationSeverity.values.firstWhere(
        (e) => e.name == rawSeverity,
        orElse: () => ViolationSeverity.critical,
      ),
      title: title,
      description: body,
      mineId: mineId,
      locationDisplay: locationDisplay,
      latitude: lat,
      longitude: lng,
      createdAt: created,
      targetSpecialist: targetSpecialist,
      instructions: instructions,
      deepLink: data['deep_link']?.toString() ?? data['action']?.toString(),
      isRead: false,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory EmergencyNotificationModel.fromJson(String source) =>
      EmergencyNotificationModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
