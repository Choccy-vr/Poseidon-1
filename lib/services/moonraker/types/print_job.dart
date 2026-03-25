class PrintJob {
  String filename;
  double progress;
  Duration timeElapsed;
  double filamentUsed;
  int? totalLayers;
  int? currentLayer;
  JobState state;

  PrintJob({
    required this.filename,
    required this.progress,
    required this.timeElapsed,
    required this.filamentUsed,
    this.totalLayers,
    this.currentLayer,
    required this.state,
  });

  factory PrintJob.fromJson(Map<String, dynamic> json) {
    return PrintJob(
      filename: json['filename'],
      progress:
          (json['info']?['current_layer']) /
          (json['info']?['total_layers'] ?? 1),
      timeElapsed: Duration(seconds: json['time_elapsed']),
      filamentUsed: json['filament_used'],
      totalLayers: json['info']?['total_layers'],
      currentLayer: json['info']?['current_layer'],
      state: JobState.values.firstWhere(
        (e) => e.toString() == 'JobState.' + json['state'],
        orElse: () => JobState.standby,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'progress': progress,
      'time_elapsed': timeElapsed.inSeconds,
      'filament_used': filamentUsed,
      'info': {'total_layers': totalLayers, 'current_layer': currentLayer},
      'state': state.toString().split('.').last,
    };
  }
}

enum JobState { standby, printing, paused, complete, error, cancelled }
