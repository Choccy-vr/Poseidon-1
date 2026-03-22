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
      actualTemp: json['actual_temp'],
      targetTemp: json['target_temp'],
      power: json['power'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name.toString().split('.').last,
      'actual_temp': actualTemp,
      'target_temp': targetTemp,
      'power': power,
    };
  }
}

enum HeaterType { extruder, heaterBed, heaterOutterBed }
