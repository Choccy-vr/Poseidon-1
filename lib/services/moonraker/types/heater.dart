class Heater {
  final HeaterType name;
  double actualTemp;
  double targetTemp;
  double power;

  Heater({
    required this.name,
    required this.actualTemp,
    required this.targetTemp,
    required this.power,
  });

  factory Heater.fromJson(Map<String, dynamic> json) {
    return Heater(
      name: HeaterType.values.firstWhere(
        (e) => e.toString() == 'HeaterType.' + json['name'],
      ),
      actualTemp: (json['temperature'] as num?)?.toDouble() ?? 0,
      targetTemp: (json['target'] as num?)?.toDouble() ?? 0,
      power: (json['power'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name.toString().split('.').last,
      'temperature': actualTemp,
      'target': targetTemp,
      'power': power,
    };
  }
}

enum HeaterType { extruder, heaterBed }
