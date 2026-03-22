class PrintJob {
  final String filename;
  double progress;
  Duration timeElapsed;
  Duration timeRemaining;

  PrintJob({
    required this.filename,
    required this.progress,
    required this.timeElapsed,
    required this.timeRemaining,
  });

  factory PrintJob.fromJson(Map<String, dynamic> json) {
    return PrintJob(
      filename: json['filename'],
      progress: json['progress'],
      timeElapsed: Duration(seconds: json['time_elapsed']),
      timeRemaining: Duration(seconds: json['time_remaining']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'progress': progress,
      'time_elapsed': timeElapsed.inSeconds,
      'time_remaining': timeRemaining.inSeconds,
    };
  }
}
