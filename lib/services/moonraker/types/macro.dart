class Macro {
  final String name;

  Macro({required this.name});

  factory Macro.fromJson(Map<String, dynamic> json) {
    return Macro(name: json['name']);
  }

  Map<String, dynamic> toJson() {
    return {'name': name};
  }
}
