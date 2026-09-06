class MineZone {
  final String id;
  final String name;
  final String depthLevel;
  final String description;

  MineZone({
    required this.id,
    required this.name,
    required this.depthLevel,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'depth_level': depthLevel,
      'description': description,
    };
  }

  factory MineZone.fromMap(Map<String, dynamic> map) {
    return MineZone(
      id: map['id'] as String,
      name: map['name'] as String,
      depthLevel: map['depth_level'] as String,
      description: map['description'] as String,
    );
  }
}

class MineModel {
  final String id;
  final String name;
  final String location;
  final String state;
  final List<MineZone> zones;

  MineModel({
    required this.id,
    required this.name,
    required this.location,
    required this.state,
    required this.zones,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'state': state,
    };
  }

  factory MineModel.fromMap(Map<String, dynamic> map, {List<MineZone>? zones}) {
    return MineModel(
      id: map['id'] as String,
      name: map['name'] as String,
      location: map['location'] as String,
      state: map['state'] as String,
      zones: zones ?? [],
    );
  }

  static List<MineZone> defaultZones = [
    MineZone(
      id: 'mz_shaft_main',
      name: 'Main Shaft',
      depthLevel: 'LVL 0M',
      description: 'Primary entry shaft and hoist muster point',
    ),
    MineZone(
      id: 'mz_seam3_gal4',
      name: 'Seam 3 - Gallery 4',
      depthLevel: 'LVL -280M',
      description: 'Active coal extraction heading with continuous miner',
    ),
    MineZone(
      id: 'mz_sec_b_face',
      name: 'Section B Face',
      depthLevel: 'LVL -320M',
      description: 'Longwall development face with hydraulic roof supports',
    ),
    MineZone(
      id: 'mz_haulage_rd2',
      name: 'Haulage Road 2',
      depthLevel: 'LVL -210M',
      description: 'Conveyor belt transfer route and shuttle car roadway',
    ),
    MineZone(
      id: 'mz_workshop_area',
      name: 'Underground Workshop Area',
      depthLevel: 'LVL -150M',
      description: 'Machinery maintenance, substation, and pump bay',
    ),
    MineZone(
      id: 'mz_vent_gal1',
      name: 'Ventilation Gallery 1',
      depthLevel: 'LVL -250M',
      description: 'Air intake and methane monitoring regulator station',
    ),
  ];
}
