class Toolhead {
  double x;
  double y;
  double z;
  double feedrate;
  List<String> homedAxes;

  Toolhead({
    required this.x,
    required this.y,
    required this.z,
    required this.feedrate,
    required this.homedAxes,
  });

  factory Toolhead.fromJson(Map<String, dynamic> json) {
    return Toolhead(
      x: json['x'],
      y: json['y'],
      z: json['z'],
      feedrate: json['feedrate'],
      homedAxes: List<String>.from(json['homed_axes']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'z': z,
      'feedrate': feedrate,
      'homed_axes': homedAxes,
    };
  }
}
