import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:poseidon_1/pages/Home_Page.dart';
import 'package:poseidon_1/services/moonraker/instance/moonraker_instance.dart';
import 'package:poseidon_1/services/moonraker/moonraker_service.dart';
import 'package:poseidon_1/services/moonraker/types/current_print_job.dart';
import 'package:poseidon_1/services/moonraker/types/print_job.dart';
import 'package:provider/provider.dart';

class PrintingPage extends StatefulWidget {
  const PrintingPage({super.key});

  @override
  State<PrintingPage> createState() => _PrintingPageState();
}

class _PrintingPageState extends State<PrintingPage> {
  bool _completionDialogShown = false;

  Future<void> _showCompletionDialog(
    BuildContext context,
    MoonrakerService service,
    String filePath,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Print Complete'),
          content: const Text('What would you like to do next?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (filePath.isNotEmpty) {
                  service.startPrint(filePath);
                }
              },
              child: const Text('Print again'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                service.clearCurrentPrintSelection();
                if (!mounted) {
                  return;
                }
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const HomePage()),
                );
              },
              child: const Text('Return'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    MoonrakerInstance.moonrakerService.refreshLatestPrintJobs();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MoonrakerService>(
      builder: (context, service, _) {
        final printer = service.currentPrinter;
        if (printer == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final job = printer.currentPrintJob;
        final file = printer.printJobs.firstWhere(
          (j) => j.status == PrintJobStatus.in_progress,
          orElse: () => PrintJob(
            jobID: '',
            filePath: job.filePath,
            exists: true,
            status: PrintJobStatus.in_progress,
            startedAt: DateTime.now(),
            printDuration: job.printDuration,
            totalDuration: job.totalDuration,
            filamentUsed: job.filamentUsed,
            metadata: PrintJobMetadata(
              size: 0,
              slicer: '',
              slicerVersion: '',
              estimatedTime: job.totalDuration,
              nozzleDiameter: 0,
              layerHeight: 0,
              firstLayerHeight: 0,
              filamentTotal: 0,
              filamentTotalWeight: 0,
              thumbnails: const [],
            ),
          ),
        );
        final extruder = printer.extruder;
        final heaterBed = printer.heaterBed;
        final fanSpeedPercent = ((printer.fan.speed) * 100).clamp(0.0, 100.0);

        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        final isPaused = job.state == CurrentPrintJobState.paused;
        final estimatedDuration = file.metadata.estimatedTime > 0
            ? file.metadata.estimatedTime
            : job.totalDuration;
        final progressBase = estimatedDuration > 0
            ? estimatedDuration
            : job.printDuration;
        final progress = progressBase > 0
            ? (job.printDuration / progressBase).clamp(0.0, 1.0)
            : 0.0;
        final timeRemaining = (estimatedDuration - job.printDuration).clamp(
          0.0,
          double.infinity,
        );
        final totalLayers = job.totalLayers ?? file.metadata.layerCount;
        final currentLayer = job.currentLayer;

        if (job.state == CurrentPrintJobState.complete &&
            !_completionDialogShown) {
          _completionDialogShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            _showCompletionDialog(context, service, file.filePath);
          });
        } else if (job.state != CurrentPrintJobState.complete &&
            _completionDialogShown) {
          _completionDialogShown = false;
        }

        return Scaffold(
          backgroundColor: colorScheme.surface,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Card(
                            color: colorScheme.surfaceContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: BorderSide(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final scale = (constraints.maxHeight / 420)
                                    .clamp(0.85, 1.2);
                                final iconSize = 20.0 * scale;

                                return Padding(
                                  padding: EdgeInsets.all(16.0 * scale),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 6,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            16 * scale,
                                          ),
                                          child: _buildFileThumbnail(
                                            file,
                                            service,
                                            colorScheme,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 12 * scale),
                                      Text(
                                        job.filePath.split('/').last,
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize:
                                              (textTheme
                                                      .titleMedium
                                                      ?.fontSize ??
                                                  16) *
                                              scale,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 10 * scale),
                                      Text(
                                        '${(progress * 100).toStringAsFixed(0)}%',
                                        style: textTheme.titleMedium?.copyWith(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                          fontSize:
                                              (textTheme
                                                      .titleMedium
                                                      ?.fontSize ??
                                                  16) *
                                              scale,
                                        ),
                                      ),
                                      SizedBox(height: 8 * scale),
                                      SizedBox(
                                        height: 14 * scale,
                                        width: double.infinity,
                                        child: LinearProgressIndicatorM3E(
                                          value: progress,
                                        ),
                                      ),
                                      SizedBox(height: 12 * scale),
                                      const Spacer(),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.schedule_outlined,
                                                size: iconSize,
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                              SizedBox(width: 4 * scale),
                                              Text(
                                                _formatDurationLabel(
                                                  timeRemaining,
                                                ),
                                                style: textTheme.bodyMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: colorScheme
                                                          .onSurfaceVariant,
                                                      fontSize:
                                                          (textTheme
                                                                  .bodyMedium
                                                                  ?.fontSize ??
                                                              14) *
                                                          scale,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.event_rounded,
                                                size: iconSize,
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                              SizedBox(width: 4 * scale),
                                              Text(
                                                _formatFinishTimeLabel(
                                                  timeRemaining,
                                                ),
                                                style: textTheme.bodyMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: colorScheme
                                                          .onSurfaceVariant,
                                                      fontSize:
                                                          (textTheme
                                                                  .bodyMedium
                                                                  ?.fontSize ??
                                                              14) *
                                                          scale,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.layers_rounded,
                                                size: iconSize,
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                              SizedBox(width: 4 * scale),
                                              Text(
                                                '${currentLayer ?? '?'} / ${totalLayers ?? '?'} layers',
                                                style: textTheme.bodyMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: colorScheme
                                                          .onSurfaceVariant,
                                                      fontSize:
                                                          (textTheme
                                                                  .bodyMedium
                                                                  ?.fontSize ??
                                                              14) *
                                                          scale,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Card(
                            color: colorScheme.surfaceContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: BorderSide(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final scale = (constraints.maxHeight / 420)
                                    .clamp(0.85, 1.2);

                                return Padding(
                                  padding: EdgeInsets.all(12.0 * scale),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: _buildTelemetryTile(
                                          context,
                                          icon: Icons.whatshot_rounded,
                                          iconColor: Colors.deepOrange,
                                          title: 'Extruder',
                                          value: _formatTempPair(
                                            extruder.actualTemp,
                                            extruder.targetTemp,
                                          ),
                                          backgroundColor: colorScheme
                                              .errorContainer
                                              .withValues(alpha: 0.35),
                                          foregroundColor: colorScheme.error,
                                          scale: scale,
                                        ),
                                      ),
                                      SizedBox(height: 8 * scale),
                                      Expanded(
                                        child: _buildTelemetryTile(
                                          context,
                                          icon: Icons.grid_on_rounded,
                                          iconColor: Colors.blue,
                                          title: 'Bed',
                                          value: _formatTempPair(
                                            heaterBed.actualTemp,
                                            heaterBed.targetTemp,
                                          ),
                                          backgroundColor: colorScheme
                                              .secondaryContainer
                                              .withValues(alpha: 0.5),
                                          foregroundColor:
                                              colorScheme.secondary,
                                          scale: scale,
                                        ),
                                      ),
                                      SizedBox(height: 8 * scale),
                                      Expanded(
                                        child: _buildTelemetryTile(
                                          context,
                                          icon: Icons.mode_fan_off_rounded,
                                          iconColor: Colors.teal,
                                          title: 'Fan',
                                          value:
                                              '${fanSpeedPercent.toStringAsFixed(0)}%',
                                          backgroundColor: colorScheme
                                              .tertiaryContainer
                                              .withValues(alpha: 0.45),
                                          foregroundColor: colorScheme.tertiary,
                                          scale: scale,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildActions(context, colorScheme, textTheme, isPaused),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTelemetryTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required Color backgroundColor,
    required Color foregroundColor,
    required double scale,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16 * scale),
        side: BorderSide(color: foregroundColor.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 10 * scale,
          vertical: 12 * scale,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 24 * scale),
            SizedBox(width: 8 * scale),
            Text(
              title,
              style: textTheme.titleSmall?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w700,
                fontSize: (textTheme.titleSmall?.fontSize ?? 14) * scale,
              ),
            ),
            SizedBox(width: 6 * scale),
            const Spacer(),
            Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                color: foregroundColor.withValues(alpha: 0.95),
                fontWeight: FontWeight.w600,
                fontSize: (textTheme.bodyMedium?.fontSize ?? 13) * scale,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTempPair(double actual, double target) {
    return '${actual.toStringAsFixed(0)}/${target.toStringAsFixed(0)}C';
  }

  Widget _buildFileThumbnail(
    PrintJob file,
    MoonrakerService service,
    ColorScheme colorScheme,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bestThumbnail = _pickBestThumbnail(
          file,
          constraints.maxWidth,
          constraints.maxHeight,
        );

        if (bestThumbnail == null) {
          return Container(
            color: Color.lerp(colorScheme.surface, Colors.black, 0.6),
            alignment: Alignment.center,
            child: Icon(
              Icons.image_not_supported_outlined,
              color: colorScheme.onSurfaceVariant,
              size: 36,
            ),
          );
        }

        return Container(
          color: Color.lerp(colorScheme.surface, Colors.black, 0.6),
          alignment: Alignment.center,
          child: Image(
            image: service.getThumbnail(
              _thumbnailRequestPath(file, bestThumbnail),
            ),
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Color.lerp(colorScheme.surface, Colors.black, 0.6),
                alignment: Alignment.center,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: colorScheme.onSurfaceVariant,
                  size: 36,
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatDurationLabel(double seconds) {
    final clamped = seconds.isFinite
        ? seconds.clamp(0.0, double.infinity)
        : 0.0;
    final duration = Duration(seconds: clamped.toInt());
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  String _formatFinishTimeLabel(double secondsRemaining) {
    final clamped = secondsRemaining.isFinite
        ? secondsRemaining.clamp(0.0, double.infinity)
        : 0.0;
    final finishAt = DateTime.now().add(Duration(seconds: clamped.toInt()));
    final rawHour = finishAt.hour;
    final hour12 = (rawHour % 12 == 0) ? 12 : rawHour % 12;
    final minute = finishAt.minute.toString().padLeft(2, '0');
    final suffix = rawHour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $suffix';
  }

  Thumbnail? _pickBestThumbnail(
    PrintJob file,
    double slotWidth,
    double slotHeight,
  ) {
    final thumbnails = file.metadata.thumbnails;
    if (thumbnails.isEmpty) {
      return null;
    }

    Thumbnail best = thumbnails.first;
    var bestScore = _thumbnailScore(best, slotWidth, slotHeight);

    for (final thumb in thumbnails.skip(1)) {
      final score = _thumbnailScore(thumb, slotWidth, slotHeight);
      if (score < bestScore) {
        best = thumb;
        bestScore = score;
      }
    }

    return best;
  }

  double _thumbnailScore(Thumbnail thumb, double slotWidth, double slotHeight) {
    final shortfallWidth = (slotWidth - thumb.width).clamp(
      0.0,
      double.infinity,
    );
    final shortfallHeight = (slotHeight - thumb.height).clamp(
      0.0,
      double.infinity,
    );
    final upscalingPenalty = (shortfallWidth + shortfallHeight) * 3;

    final widthDelta = (thumb.width - slotWidth).abs();
    final heightDelta = (thumb.height - slotHeight).abs();

    final slotAspect = slotHeight <= 0 ? 1.0 : slotWidth / slotHeight;
    final thumbAspect = thumb.height == 0 ? 1.0 : thumb.width / thumb.height;
    final aspectDelta = (slotAspect - thumbAspect).abs() * 120;

    return widthDelta + heightDelta + aspectDelta + upscalingPenalty;
  }

  String _thumbnailRequestPath(PrintJob file, Thumbnail thumb) {
    final rawFilePath = file.filePath.trim().replaceAll('\\', '/');
    var normalizedFilePath = rawFilePath.startsWith('/gcodes/')
        ? rawFilePath.substring('/gcodes/'.length)
        : rawFilePath;
    normalizedFilePath = normalizedFilePath.startsWith('gcodes/')
        ? normalizedFilePath.substring('gcodes/'.length)
        : normalizedFilePath;
    normalizedFilePath = normalizedFilePath.startsWith('/')
        ? normalizedFilePath.substring(1)
        : normalizedFilePath;

    final slashIndex = normalizedFilePath.lastIndexOf('/');
    final parentDir = slashIndex == -1
        ? ''
        : normalizedFilePath.substring(0, slashIndex);

    final thumbPath = thumb.path.trim().replaceAll('\\', '/');
    if (thumbPath.isEmpty) {
      return '';
    }

    if (thumbPath.startsWith('/')) {
      return thumbPath.substring(1);
    }

    if (thumbPath.startsWith('gcodes/')) {
      return thumbPath.substring('gcodes/'.length);
    }

    if (parentDir.isEmpty) {
      return thumbPath;
    }

    return '${parentDir.endsWith('/') ? parentDir.substring(0, parentDir.length - 1) : parentDir}/$thumbPath';
  }

  Widget _buildActions(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isPaused,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: colorScheme.copyWith(
                primary: isPaused
                    ? colorScheme.primary
                    : colorScheme.primaryContainer,
                onPrimary: isPaused
                    ? colorScheme.onPrimary
                    : colorScheme.onPrimaryContainer,
              ),
            ),
            child: ButtonM3E(
              onPressed: () {
                isPaused
                    ? context.read<MoonrakerService>().resumePrint()
                    : context.read<MoonrakerService>().pausePrint();
              },
              label: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isPaused
                          ? Icons.play_arrow_outlined
                          : Icons.pause_outlined,
                      size: 32,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isPaused ? 'Resume' : 'Pause',
                      style: textTheme.titleLarge?.copyWith(
                        color: isPaused
                            ? colorScheme.onPrimary
                            : colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              shape: ButtonM3EShape.square,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: colorScheme.copyWith(
                primary: colorScheme.error,
                onPrimary: colorScheme.onError,
              ),
            ),
            child: ButtonM3E(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (dialogContext) {
                    return AlertDialog(
                      title: const Text('Cancel Print'),
                      content: const Text(
                        'Are you sure you want to cancel the print?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('No'),
                        ),
                        FilledButton(
                          onPressed: () {
                            context.read<MoonrakerService>().cancelPrint();
                            Navigator.of(dialogContext).pop();
                          },
                          child: const Text('Yes'),
                        ),
                      ],
                    );
                  },
                );
              },
              label: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cancel_outlined, size: 32),
                    const SizedBox(width: 8),
                    Text(
                      'Cancel',
                      style: textTheme.titleLarge?.copyWith(
                        color: colorScheme.onError,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              shape: ButtonM3EShape.square,
            ),
          ),
        ),
      ],
    );
  }
}
