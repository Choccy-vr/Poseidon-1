class Fan {
  double speed;

  Fan({required this.speed});

  factory Fan.fromJson(Map<String, dynamic> json) {
    return Fan(speed: (json['speed'] as num?)?.toDouble() ?? 0.0);
  }

  Map<String, dynamic> toJson() {
    return {'speed': speed};
  }
}
