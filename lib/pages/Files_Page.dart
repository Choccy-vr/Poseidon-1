import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:poseidon_1/services/moonraker/instance/moonraker_instance.dart';
import 'package:poseidon_1/services/moonraker/moonraker_service.dart';
import 'package:poseidon_1/services/moonraker/types/print_job.dart';
import 'package:poseidon_1/widget/navigation_rail.dart';
import 'package:provider/provider.dart';

enum _FilesSortOrder { newest, oldest }

class FilesPage extends StatefulWidget {
  const FilesPage({super.key});

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  _FilesSortOrder _sortOrder = _FilesSortOrder.newest;
  PrintJob? _selected;

  String _formatDurationHm(double seconds) {
    final duration = Duration(seconds: seconds.round());
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppNavigationScaffold(
      selectedIndex: 1,
      body: Material(
        color: colorScheme.surfaceContainerLow,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: Consumer<MoonrakerService>(
          builder: (context, service, child) {
            final jobs = List<PrintJob>.from(
              service.currentPrinter?.printJobs ?? const <PrintJob>[],
            ).where((job) => job.exists).toList();

            jobs.sort((a, b) {
              final comparison = a.startedAt.compareTo(b.startedAt);
              return _sortOrder == _FilesSortOrder.newest
                  ? comparison * -1
                  : comparison;
            });

            PrintJob? selectedJob;
            if (_selected != null) {
              for (final job in jobs) {
                if (job.jobID == _selected!.jobID) {
                  selectedJob = job;
                  break;
                }
              }
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Row(
                        children: [
                          Text(
                            'Sort',
                            style: textTheme.labelLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 126,
                            child: DropdownButtonFormField<_FilesSortOrder>(
                              initialValue: _sortOrder,
                              isDense: true,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: colorScheme.surfaceContainerHigh,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: colorScheme.outlineVariant,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: colorScheme.outlineVariant,
                                  ),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: _FilesSortOrder.newest,
                                  child: Text('Newest'),
                                ),
                                DropdownMenuItem(
                                  value: _FilesSortOrder.oldest,
                                  child: Text('Oldest'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }

                                setState(() {
                                  _sortOrder = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (selectedJob != null)
                        IconButton(
                          tooltip: 'Delete file',
                          onPressed: () => _confirmDeleteSelected(
                            context,
                            service,
                            selectedJob!,
                          ),
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: colorScheme.error,
                          ),
                        ),
                    ],
                  ),
                ),
                Divider(height: 1, color: colorScheme.outlineVariant),
                const SizedBox(height: 8),
                Expanded(
                  child: jobs.isEmpty
                      ? Center(
                          child: Text(
                            'No stored print jobs',
                            style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(32.0),
                          itemCount: jobs.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 32,
                                mainAxisExtent: 280,
                              ),
                          itemBuilder: (context, index) {
                            return _buildFileItem(jobs[index]);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFileItem(PrintJob file) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () {
        // show print dialog
      },
      onLongPress: () {
        //select file item
        setState(() {
          if (_selected == file) {
            _selected = null;
          } else {
            _selected = file;
          }
        });
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        color: _isSelected(file)
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainer,
        elevation: _isSelected(file) ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: _isSelected(file)
                ? colorScheme.primary
                : colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              flex: 7,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bestThumbnail = _pickBestThumbnail(
                    file,
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );

                  if (bestThumbnail == null) {
                    return Container(
                      color: colorScheme.surfaceContainerHigh,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: colorScheme.onSurfaceVariant,
                        size: 36,
                      ),
                    );
                  }

                  return Container(
                    color: colorScheme.surfaceContainerHigh,
                    alignment: Alignment.center,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Image(
                        image: MoonrakerInstance.moonrakerService.getThumbnail(
                          _thumbnailRequestPath(file, bestThumbnail),
                        ),
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: colorScheme.surfaceContainerHigh,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: colorScheme.onSurfaceVariant,
                              size: 36,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.filePath.split('/').last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.scale_rounded,
                              color: colorScheme.onSurfaceVariant,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${file.metadata.filamentTotalWeight.toStringAsFixed(2)} g',
                              style: textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.layers_rounded,
                              color: colorScheme.onSurfaceVariant,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${file.metadata.layerHeight.toStringAsFixed(2)} mm',
                              style: textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_rounded,
                              color: colorScheme.onSurfaceVariant,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDurationHm(file.metadata.estimatedTime),
                              style: textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

    var normalizedThumbPath = thumbPath.startsWith('/gcodes/')
        ? thumbPath.substring('/gcodes/'.length)
        : thumbPath;
    normalizedThumbPath = normalizedThumbPath.startsWith('gcodes/')
        ? normalizedThumbPath.substring('gcodes/'.length)
        : normalizedThumbPath;
    normalizedThumbPath = normalizedThumbPath.startsWith('/')
        ? normalizedThumbPath.substring(1)
        : normalizedThumbPath;

    // Moonraker metadata `relative_path` is relative to the gcode file's parent.
    if (normalizedThumbPath.startsWith('.thumbs/')) {
      if (parentDir.isEmpty) {
        return normalizedThumbPath;
      }
      return '$parentDir/$normalizedThumbPath';
    }

    return normalizedThumbPath;
  }

  bool _isSelected(PrintJob file) {
    return _selected?.jobID == file.jobID;
  }

  Future<void> _confirmDeleteSelected(
    BuildContext context,
    MoonrakerService service,
    PrintJob selectedJob,
  ) async {
    final fileName = selectedJob.filePath.split('/').last;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete file?'),
          content: Text('Delete "$fileName" from printer storage?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    service.deleteFile(_deleteRequestPath(selectedJob));
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final refreshedJobs = await service.getLatestPrintJobs();
    service.currentPrinter?.printJobs = refreshedJobs;

    if (!mounted) {
      return;
    }

    setState(() {
      _selected = null;
    });
  }

  String _deleteRequestPath(PrintJob file) {
    final rawPath = file.filePath.trim().replaceAll('\\', '/');
    var normalizedPath = rawPath.startsWith('/gcodes/')
        ? rawPath.substring('/gcodes/'.length)
        : rawPath;
    normalizedPath = normalizedPath.startsWith('gcodes/')
        ? normalizedPath.substring('gcodes/'.length)
        : normalizedPath;
    normalizedPath = normalizedPath.startsWith('/')
        ? normalizedPath.substring(1)
        : normalizedPath;

    return 'gcodes/$normalizedPath';
  }
}
