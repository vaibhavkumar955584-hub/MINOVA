import '../../models/mine_model.dart';

class MineDto {
  final String mineId;
  final String mineName;
  final Object? location;
  final String state;
  final Object? coalfield;
  final Object? district;
  final Object? operatorName;
  final Object? status;
  final Object? methaneLevel;
  final Object? gasBreach;
  final Object? riskLevel;
  final Object? inspectorInCharge;

  const MineDto({required this.mineId, required this.mineName, required this.location, required this.state, this.coalfield, this.district, this.operatorName, this.status, this.methaneLevel, this.gasBreach, this.riskLevel, this.inspectorInCharge});

  factory MineDto.fromJson(Map<String, dynamic> json) => MineDto(
        mineId: json['mine_id'] as String,
        mineName: json['mine_name'] as String,
        location: json['location'],
        state: json['state'] as String,
        coalfield: json['coalfield'], district: json['district'], operatorName: json['operator'], status: json['status'], methaneLevel: json['methane_level'], gasBreach: json['gas_breach'], riskLevel: json['risk_level'], inspectorInCharge: json['inspector_in_charge'],
      );

  factory MineDto.fromDomain(MineModel mine) => MineDto(
        mineId: mine.id,
        mineName: mine.name,
        location: mine.location,
        state: mine.state,
      );

  MineModel toDomain() => MineModel(id: mineId, name: mineName, location: location?.toString() ?? '', state: state, zones: const []);

  Map<String, dynamic> toJson() => {'mine_id': mineId, 'mine_name': mineName, 'coalfield': coalfield, 'state': state, 'district': district, 'operator': operatorName, 'status': status, 'location': location, 'methane_level': methaneLevel, 'gas_breach': gasBreach, 'risk_level': riskLevel, 'inspector_in_charge': inspectorInCharge};
}
