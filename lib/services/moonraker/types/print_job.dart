class PrintJob {
  String jobID;
  String filePath;
  bool exists;
  PrintJobStatus status;
  DateTime startedAt; //arrives as unix time
  DateTime? completedAt; //arives as unix time
  double printDuration; //seconds
  double totalDuration; //seconds
  double filamentUsed; //mm
  PrintJobMetadata metadata;

  PrintJob({
    required this.jobID,
    required this.filePath,
    required this.exists,
    required this.status,
    required this.startedAt,
    this.completedAt,
    required this.printDuration,
    required this.totalDuration,
    required this.filamentUsed,
    required this.metadata,
  });

  factory PrintJob.fromJson(Map<String, dynamic> json) {
    final startSeconds = _asDouble(json['start_time']);
    final endSeconds = json['end_time'] == null
        ? null
        : _asDouble(json['end_time']);

    return PrintJob(
      jobID: (json['job_id'] ?? '').toString(),
      filePath: (json['filename'] ?? '').toString(),
      exists: json['exists'] == true,
      status: PrintJobStatus.values.firstWhere(
        (e) => e.toString() == 'PrintJobStatus.' + (json['status'] ?? ''),
        orElse: () => PrintJobStatus.error,
      ),
      startedAt: DateTime.fromMillisecondsSinceEpoch(
        (startSeconds * 1000).round(),
      ),
      completedAt: endSeconds != null
          ? DateTime.fromMillisecondsSinceEpoch((endSeconds * 1000).round())
          : null,
      printDuration: _asDouble(json['print_duration']),
      totalDuration: _asDouble(json['total_duration']),
      filamentUsed: _asDouble(json['filament_used']),
      metadata: PrintJobMetadata.fromJson(
        json['metadata'] is Map<String, dynamic>
            ? json['metadata'] as Map<String, dynamic>
            : <String, dynamic>{},
      ),
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
}

enum PrintJobStatus {
  in_progress,
  completed,
  cancelled,
  error,
  klippy_shutdown,
  klippy_disconnect,
  interrupted,
}

class PrintJobMetadata {
  int size; //bytes
  String slicer;
  String slicerVersion;
  double estimatedTime; //seconds
  int? layerCount;
  double nozzleDiameter; //mm
  double layerHeight; //mm
  double firstLayerHeight; //mm
  double filamentTotal; //mm
  double filamentTotalWeight; //grams
  List<Thumbnail> thumbnails;

  PrintJobMetadata({
    required this.size,
    required this.slicer,
    required this.slicerVersion,
    required this.estimatedTime,
    this.layerCount,
    required this.nozzleDiameter,
    required this.layerHeight,
    required this.firstLayerHeight,
    required this.filamentTotal,
    required this.filamentTotalWeight,
    required this.thumbnails,
  });

  factory PrintJobMetadata.fromJson(Map<String, dynamic> json) {
    final rawThumbnails = json['thumbnails'];
    final thumbnails = <Thumbnail>[];

    if (rawThumbnails is List) {
      for (final entry in rawThumbnails) {
        if (entry is Map) {
          thumbnails.add(Thumbnail.fromJson(Map<String, dynamic>.from(entry)));
        }
      }
    }

    return PrintJobMetadata(
      size: _asInt(json['size']),
      slicer: (json['slicer'] ?? '').toString(),
      slicerVersion: (json['slicer_version'] ?? '').toString(),
      estimatedTime: _asDouble(json['estimated_time']),
      layerCount:
          _asNullableInt(json['layer_count']) ??
          _asNullableInt(json['total_layer']) ??
          _asNullableInt(json['total_layers']),
      nozzleDiameter: _asDouble(json['nozzle_diameter']),
      layerHeight: _asDouble(json['layer_height']),
      firstLayerHeight: _asDouble(json['first_layer_height']),
      filamentTotal: _asDouble(json['filament_total']),
      filamentTotalWeight: _asDouble(json['filament_weight_total']),
      thumbnails: thumbnails,
    );
  }

  static int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.round() ?? fallback;
    }
    return fallback;
  }

  static int? _asNullableInt(dynamic value) {
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
      return int.tryParse(value) ?? double.tryParse(value)?.round();
    }
    return null;
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
}

class Thumbnail {
  int width;
  int height;
  int size; //bytes
  String path;

  Thumbnail({
    required this.width,
    required this.height,
    required this.size,
    required this.path,
  });

  factory Thumbnail.fromJson(Map<String, dynamic> json) {
    final relativePath = (json['relative_path'] ?? '').toString();
    final rootRelativePath = (json['thumbnail_path'] ?? '').toString();

    return Thumbnail(
      width: _asInt(json['width']),
      height: _asInt(json['height']),
      size: _asInt(json['size']),
      path: rootRelativePath.isNotEmpty ? rootRelativePath : relativePath,
    );
  }

  static int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.round() ?? fallback;
    }
    return fallback;
  }
}
