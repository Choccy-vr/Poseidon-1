class Macro {
  final String name;
  final String gcode;

  Macro({required this.name, required this.gcode});

  factory Macro.fromJson(Map<String, dynamic> json) {
    return Macro(name: json['name'] as String, gcode: json['gcode'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'gcode': gcode};
  }
}
