class Fan {
  final String name;
  double speed;

  Fan({required this.name, required this.speed});

  factory Fan.fromJson(Map<String, dynamic> json) {
    return Fan(name: json['name'], speed: json['speed']);
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'speed': speed};
  }
}
