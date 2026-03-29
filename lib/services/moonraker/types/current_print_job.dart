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
    return CurrentPrintJob(
      filePath: json['filename'],
      state: CurrentPrintJobState.values.firstWhere(
        (e) => e.toString() == 'CurrentPrintJobState.' + json['state'],
        orElse: () => CurrentPrintJobState.standby,
      ),
      message: json['message'] ?? '',
      totalDuration: json['total_duration'],
      printDuration: json['print_duration'],
      filamentUsed: json['filament_used'],
      totalLayers: json['info']['total_layers'] != null
          ? int.tryParse(json['info']['total_layers'].toString())
          : null,
      currentLayer: json['info']['current_layer'] != null
          ? int.tryParse(json['info']['current_layer'].toString())
          : null,
    );
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
