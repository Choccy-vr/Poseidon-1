class CurrentPrintJob {
  String filePath;
  double totalDuration; //seconds
  double printDuration; //seconds
  double filamentUsed; //mm
  CurrentPrintJobState state;
  String message;
  int? totalLayers;
  int? currentLayer;

  CurrentPrintJob({
    required this.filePath,
    required this.totalDuration,
    required this.printDuration,
    required this.filamentUsed,
    required this.state,
    required this.message,
    this.totalLayers,
    this.currentLayer,
  });

  factory CurrentPrintJob.fromJson(Map<String, dynamic> json) {
    final info = json['info'] is Map<String, dynamic>
        ? json['info'] as Map<String, dynamic>
        : <String, dynamic>{};

    return CurrentPrintJob(
      filePath: (json['filename'] ?? '').toString(),
      state: CurrentPrintJobState.values.firstWhere(
        (e) => e.toString() == 'CurrentPrintJobState.${json['state']}',
        orElse: () => CurrentPrintJobState.standby,
      ),
      message: json['message'] ?? '',
      totalDuration: _asDouble(json['total_duration']),
      printDuration: _asDouble(json['print_duration']),
      filamentUsed: _asDouble(json['filament_used']),
      totalLayers:
          _asInt(info['total_layer']) ??
          _asInt(info['total_layers']) ??
          _asInt(json['total_layer']) ??
          _asInt(json['total_layers']),
      currentLayer:
          _asInt(info['current_layer']) ??
          _asInt(info['current_layers']) ??
          _asInt(json['current_layer']) ??
          _asInt(json['current_layers']),
    );
  }

  static double _asDouble(dynamic value, [double fallback = 0.0]) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  static int? _asInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      final intValue = int.tryParse(value);
      if (intValue != null) {
        return intValue;
      }
      final doubleValue = double.tryParse(value);
      if (doubleValue != null) {
        return doubleValue.round();
      }
    }
    return null;
  }
}

enum CurrentPrintJobState {
  standby,
  printing,
  paused,
  complete,
  error,
  cancelled,
}
