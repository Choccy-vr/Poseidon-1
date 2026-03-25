class Toolhead {
  double x;
  double y;
  double z;
  double e;
  String homedAxes;

  Toolhead({
    required this.x,
    required this.y,
    required this.z,
    required this.e,
    required this.homedAxes,
  });

  factory Toolhead.fromJson(Map<String, dynamic> json) {
    final List<double> position = List<double>.from(json['position']);
    return Toolhead(
      x: position[0],
      y: position[1],
      z: position[2],
      e: position[3],
      homedAxes: json['homed_axes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'x': x, 'y': y, 'z': z, 'homed_axes': homedAxes};
  }
}
