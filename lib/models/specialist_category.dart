import 'package:flutter/material.dart';

/// Supported Employee / Field Responder Specialist Categories
enum SpecialistCategory {
  mechanical,
  electrical,
  miningEquipment,
  ventilation,
  fireSafety,
  rescue,
  medical,
  electricalMaintenance,
  machineryTechnician,
  general;

  String get key {
    switch (this) {
      case SpecialistCategory.mechanical:
        return 'mechanical';
      case SpecialistCategory.electrical:
        return 'electrical';
      case SpecialistCategory.miningEquipment:
        return 'mining_equipment';
      case SpecialistCategory.ventilation:
        return 'ventilation';
      case SpecialistCategory.fireSafety:
        return 'fire_safety';
      case SpecialistCategory.rescue:
        return 'rescue';
      case SpecialistCategory.medical:
        return 'medical';
      case SpecialistCategory.electricalMaintenance:
        return 'electrical_maintenance';
      case SpecialistCategory.machineryTechnician:
        return 'machinery_technician';
      case SpecialistCategory.general:
        return 'general';
    }
  }

  String get displayName {
    switch (this) {
      case SpecialistCategory.mechanical:
        return 'Mechanical Specialist';
      case SpecialistCategory.electrical:
        return 'Electrician';
      case SpecialistCategory.miningEquipment:
        return 'Mining Equipment Operator';
      case SpecialistCategory.ventilation:
        return 'Ventilation Officer';
      case SpecialistCategory.fireSafety:
        return 'Fire & Safety Officer';
      case SpecialistCategory.rescue:
        return 'Mines Rescue Squad';
      case SpecialistCategory.medical:
        return 'First Aid & Medical';
      case SpecialistCategory.electricalMaintenance:
        return 'Electrical Maintenance';
      case SpecialistCategory.machineryTechnician:
        return 'Machinery Technician';
      case SpecialistCategory.general:
        return 'General Field Responder';
    }
  }

  String get hindiName {
    switch (this) {
      case SpecialistCategory.mechanical:
        return 'मैकेनिकल विशेषज्ञ';
      case SpecialistCategory.electrical:
        return 'इलेक्ट्रीशियन';
      case SpecialistCategory.miningEquipment:
        return 'खनन उपकरण ऑपरेटर';
      case SpecialistCategory.ventilation:
        return 'वेंटिलेशन व गैस विशेषज्ञ';
      case SpecialistCategory.fireSafety:
        return 'अग्निशमन एवं सुरक्षा';
      case SpecialistCategory.rescue:
        return 'खान बचाव दस्ता (Rescue)';
      case SpecialistCategory.medical:
        return 'प्राथमिक चिकित्सा व मेडिकल';
      case SpecialistCategory.electricalMaintenance:
        return 'विद्युत अनुरक्षण';
      case SpecialistCategory.machineryTechnician:
        return 'मशीनरी तकनीशियन';
      case SpecialistCategory.general:
        return 'फील्ड रेस्पोंडर (सामान्य)';
    }
  }

  IconData get icon {
    switch (this) {
      case SpecialistCategory.mechanical:
        return Icons.handyman_rounded;
      case SpecialistCategory.electrical:
        return Icons.bolt_rounded;
      case SpecialistCategory.miningEquipment:
        return Icons.agriculture_rounded;
      case SpecialistCategory.ventilation:
        return Icons.air_rounded;
      case SpecialistCategory.fireSafety:
        return Icons.local_fire_department_rounded;
      case SpecialistCategory.rescue:
        return Icons.health_and_safety_rounded;
      case SpecialistCategory.medical:
        return Icons.medical_services_rounded;
      case SpecialistCategory.electricalMaintenance:
        return Icons.electrical_services_rounded;
      case SpecialistCategory.machineryTechnician:
        return Icons.build_circle_rounded;
      case SpecialistCategory.general:
        return Icons.engineering_rounded;
    }
  }

  static SpecialistCategory fromKey(String? raw) {
    if (raw == null) return SpecialistCategory.general;
    final clean = raw.trim().toLowerCase();
    for (final cat in SpecialistCategory.values) {
      if (cat.key == clean ||
          cat.name.toLowerCase() == clean ||
          cat.displayName.toLowerCase() == clean) {
        return cat;
      }
    }
    // Partial substring fallback
    if (clean.contains('mech')) return SpecialistCategory.mechanical;
    if (clean.contains('elect') && clean.contains('maint')) {
      return SpecialistCategory.electricalMaintenance;
    }
    if (clean.contains('elect')) return SpecialistCategory.electrical;
    if (clean.contains('equip') || clean.contains('hemm')) {
      return SpecialistCategory.miningEquipment;
    }
    if (clean.contains('vent') || clean.contains('gas')) {
      return SpecialistCategory.ventilation;
    }
    if (clean.contains('fire')) return SpecialistCategory.fireSafety;
    if (clean.contains('rescue')) return SpecialistCategory.rescue;
    if (clean.contains('med') || clean.contains('aid')) {
      return SpecialistCategory.medical;
    }
    if (clean.contains('tech')) return SpecialistCategory.machineryTechnician;
    return SpecialistCategory.general;
  }
}
