class Macro {
  final String name;
  final String gcode;

  Macro({required this.name, required this.gcode});

  factory Macro.fromJson(Map<String, dynamic> json) {
    return Macro(name: json['name'], gcode: json['gcode']);
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'gcode': gcode};
  }
}
