import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:poseidon_1/pages/Files_Page.dart';
import 'package:poseidon_1/pages/Tune_Page.dart';
import 'package:poseidon_1/services/moonraker/types/current_print_job.dart';
import 'package:poseidon_1/services/moonraker/moonraker_service.dart';
import 'package:poseidon_1/widget/navigation_rail.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppNavigationScaffold(
      selectedIndex: 0,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildQuickStats(colorScheme, textTheme),
            SizedBox(height: 16),
            Expanded(child: _buildQuickActions(colorScheme, textTheme)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(ColorScheme colorScheme, TextTheme textTheme) {
    return Material(
      color: colorScheme.surfaceContainerLow,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildTemperature(colorScheme, textTheme)),
              const SizedBox(width: 10),
              _buildStatus(colorScheme, textTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemperature(ColorScheme colorScheme, TextTheme textTheme) {
    return Consumer<MoonrakerService>(
      builder: (context, service, child) {
        final extruder = service.currentPrinter?.extruder;
        final heaterBed = service.currentPrinter?.heaterBed;

        return Material(
          color: colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.outline),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.whatshot_rounded,
                      fill: 1.0,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      extruder == null
                          ? '--.-°C'
                          : '${extruder.actualTemp.toStringAsFixed(1)}°C',
                      style: textTheme.titleLarge?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      extruder == null
                          ? 'Target: --.-°C'
                          : 'Target: ${extruder.targetTemp.toStringAsFixed(1)}°C',
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              VerticalDivider(
                color: colorScheme.outlineVariant,
                thickness: 1,
                width: 1,
                indent: 16,
                endIndent: 16,
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.grid_on_rounded,
                      fill: 1.0,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      heaterBed == null
                          ? '--.-°C'
                          : '${heaterBed.actualTemp.toStringAsFixed(1)}°C',
                      style: textTheme.titleLarge?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      heaterBed == null
                          ? 'Target: --.-°C'
                          : 'Target: ${heaterBed.targetTemp.toStringAsFixed(1)}°C',
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatus(ColorScheme colorScheme, TextTheme textTheme) {
    return Consumer<MoonrakerService>(
      builder: (context, service, child) {
        final printer = service.currentPrinter;
        final CurrentPrintJobState? jobState = printer?.currentPrintJob.state;

        final bool isDisconnected = printer == null;
        final bool isPrinting = jobState == CurrentPrintJobState.printing;
        final bool isPaused = jobState == CurrentPrintJobState.paused;

        final Color backgroundColor;
        final Color foregroundColor;
        final IconData icon;
        final String label;

        if (isDisconnected) {
          backgroundColor = colorScheme.errorContainer;
          foregroundColor = colorScheme.onErrorContainer;
          icon = Icons.portable_wifi_off_rounded;
          label = 'Disconnected';
        } else if (isPrinting) {
          backgroundColor = colorScheme.primaryContainer;
          foregroundColor = colorScheme.onPrimaryContainer;
          icon = Icons.local_fire_department_rounded;
          label = 'Printing';
        } else if (isPaused) {
          backgroundColor = colorScheme.tertiaryContainer;
          foregroundColor = colorScheme.onTertiaryContainer;
          icon = Icons.pause_circle_rounded;
          label = 'Paused';
        } else {
          backgroundColor = const Color.fromARGB(255, 12, 81, 48);
          foregroundColor = const Color.fromARGB(255, 175, 241, 196);
          icon = Icons.check_circle;
          label = 'Idle';
        }

        return Material(
          color: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outline),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, fill: 1.0, color: foregroundColor),
                Text(
                  label,
                  style: textTheme.titleMedium?.copyWith(
                    color: foregroundColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(ColorScheme colorScheme, TextTheme textTheme) {
    return Material(
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const FilesPage()),
                  );
                },
                child: Container(
                  height: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 64.0,
                    vertical: 48.0,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.folder_rounded,
                          fill: 1.0,
                          color: colorScheme.onSecondaryContainer,
                          size: 64,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Files',
                          style: textTheme.headlineLarge?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const TunePage()),
                  );
                },
                child: Container(
                  height: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 64.0,
                    vertical: 48.0,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.device_thermostat_rounded,
                          fill: 1.0,
                          color: colorScheme.onSecondaryContainer,
                          size: 64,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Temp',
                          style: textTheme.headlineLarge?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
