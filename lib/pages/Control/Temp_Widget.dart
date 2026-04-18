import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:poseidon_1/services/moonraker/moonraker_service.dart';
import 'package:provider/provider.dart';

class TempWidget extends StatelessWidget {
  const TempWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Material(
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Consumer<MoonrakerService>(
                  builder: (context, service, child) {
                    final extruder = service.currentPrinter?.extruder;
                    final heaterBed = service.currentPrinter?.heaterBed;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _buildHeaterColumn(
                            context,
                            colorScheme,
                            textTheme,
                            icon: Icons.whatshot_rounded,
                            iconColor: Colors.deepOrange,
                            name: 'Extruder',
                            containerColor: colorScheme.errorContainer
                                .withValues(alpha: 0.3),
                            onContainerColor: colorScheme.error,
                            actualTemp: extruder?.actualTemp ?? 0.0,
                            targetTemp: extruder?.targetTemp ?? 0.0,
                            onTargetChanged: (newTarget) {
                              service.setExtruderTemperature(newTarget);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildHeaterColumn(
                            context,
                            colorScheme,
                            textTheme,
                            icon: Icons.grid_on_rounded,
                            iconColor: Colors.blue,
                            name: 'Bed',
                            containerColor: colorScheme.secondaryContainer
                                .withValues(alpha: 0.5),
                            onContainerColor: colorScheme.secondary,
                            actualTemp: heaterBed?.actualTemp ?? 0.0,
                            targetTemp: heaterBed?.targetTemp ?? 0.0,
                            onTargetChanged: (newTarget) {
                              service.setBedTemperature(newTarget);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              _buildPresets(context, colorScheme, textTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaterColumn(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    required IconData icon,
    required Color iconColor,
    required String name,
    required Color containerColor,
    required Color onContainerColor,
    required double actualTemp,
    required double targetTemp,
    required ValueChanged<double> onTargetChanged,
  }) {
    return Material(
      color: containerColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: onContainerColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: 36),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: textTheme.titleMedium?.copyWith(
                    color: onContainerColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              '${actualTemp.toStringAsFixed(1)}°C',
              style: textTheme.displaySmall?.copyWith(
                color: onContainerColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Target: ${targetTemp.toStringAsFixed(1)}°C',
              style: textTheme.titleMedium?.copyWith(
                color: onContainerColor.withValues(alpha: 0.8),
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _buildAdjustButton(context, '-5', () {
                    onTargetChanged((targetTemp - 5).clamp(0, 300));
                  }, onContainerColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildAdjustButton(context, '-1', () {
                    onTargetChanged((targetTemp - 1).clamp(0, 300));
                  }, onContainerColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildAdjustButton(context, '+1', () {
                    onTargetChanged((targetTemp + 1).clamp(0, 300));
                  }, onContainerColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildAdjustButton(context, '+5', () {
                    onTargetChanged((targetTemp + 5).clamp(0, 300));
                  }, onContainerColor),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ButtonM3E(
                onPressed: () => onTargetChanged(0),
                label: Text(
                  'Off',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                shape: ButtonM3EShape.square,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjustButton(
    BuildContext context,
    String label,
    VoidCallback onPressed,
    Color tintColor,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: tintColor.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHigh.withValues(alpha: 0.8),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: tintColor,
          ),
        ),
      ),
    );
  }

  Widget _buildPresets(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(child: _buildPresetButton(context, 'Cool', 0, 0)),
        const SizedBox(width: 12),
        Expanded(child: _buildPresetButton(context, 'PLA', 210, 60)),
        const SizedBox(width: 12),
        Expanded(child: _buildPresetButton(context, 'PETG', 240, 70)),
        const SizedBox(width: 12),
        Expanded(child: _buildPresetButton(context, 'ABS', 260, 100)),
      ],
    );
  }

  Widget _buildPresetButton(
    BuildContext context,
    String label,
    double nozzleTemp,
    double bedTemp,
  ) {
    return SizedBox(
      height: 64,
      child: ButtonM3E(
        onPressed: () {
          final service = context.read<MoonrakerService>();
          if (nozzleTemp > 0) {
            service.setExtruderTemperature(nozzleTemp);
          } else {
            service.setExtruderTemperature(0);
          }
          if (bedTemp > 0) {
            service.setBedTemperature(bedTemp);
          } else {
            service.setBedTemperature(0);
          }
        },
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        shape: ButtonM3EShape.square,
      ),
    );
  }
}
