import 'package:flutter/material.dart';
import 'package:poseidon_1/services/moonraker/instance/moonraker_instance.dart';
import 'package:poseidon_1/services/moonraker/moonraker_service.dart';
import 'package:provider/provider.dart';

class MoveWidget extends StatefulWidget {
  const MoveWidget({super.key});

  @override
  State<MoveWidget> createState() => _MoveWidgetState();
}

class _MoveWidgetState extends State<MoveWidget> {
  int _stepSize = 10;

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Axis Movement',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  _buildStepSelector(colorScheme, textTheme),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 4,
                      child: _buildXYPad(colorScheme, textTheme),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _buildZPad(colorScheme, textTheme),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: _buildPositionInfo(colorScheme, textTheme),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepSelector(ColorScheme colorScheme, TextTheme textTheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStepBtn(1, '1mm', colorScheme, textTheme),
        const SizedBox(width: 8),
        _buildStepBtn(10, '10mm', colorScheme, textTheme),
        const SizedBox(width: 8),
        _buildStepBtn(50, '50mm', colorScheme, textTheme),
        const SizedBox(width: 8),
        _buildStepBtn(100, '100mm', colorScheme, textTheme),
      ],
    );
  }

  Widget _buildStepBtn(
    int value,
    String label,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final isSelected = _stepSize == value;
    final bgColor = isSelected
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHigh;
    final fgColor = isSelected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;
    final borderColor = isSelected
        ? colorScheme.primary
        : colorScheme.outlineVariant;

    return InkWell(
      onTap: () {
        setState(() {
          _stepSize = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor.withValues(alpha: isSelected ? 1.0 : 0.5),
          ),
        ),
        child: Text(
          label,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: fgColor,
          ),
        ),
      ),
    );
  }

  Widget _buildXYPad(ColorScheme colorScheme, TextTheme textTheme) {
    return Material(
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  const Spacer(),
                  Expanded(
                    child: _buildMoveBtn(
                      'y',
                      _stepSize.toDouble(),
                      Icons.keyboard_arrow_up_rounded,
                      'Y+',
                      colorScheme,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _buildMoveBtn(
                      'x',
                      -_stepSize.toDouble(),
                      Icons.keyboard_arrow_left_rounded,
                      'X-',
                      colorScheme,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _buildHomeBtn('x y', colorScheme)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMoveBtn(
                      'x',
                      _stepSize.toDouble(),
                      Icons.keyboard_arrow_right_rounded,
                      'X+',
                      colorScheme,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  const Spacer(),
                  Expanded(
                    child: _buildMoveBtn(
                      'y',
                      -_stepSize.toDouble(),
                      Icons.keyboard_arrow_down_rounded,
                      'Y-',
                      colorScheme,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZPad(ColorScheme colorScheme, TextTheme textTheme) {
    return Material(
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildMoveBtn(
                'z',
                _stepSize.toDouble(),
                Icons.keyboard_double_arrow_up_rounded,
                'Z+',
                colorScheme,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildHomeBtn('z', colorScheme)),
            const SizedBox(height: 8),
            Expanded(
              child: _buildMoveBtn(
                'z',
                -_stepSize.toDouble(),
                Icons.keyboard_double_arrow_down_rounded,
                'Z-',
                colorScheme,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoveBtn(
    String axis,
    double distance,
    IconData icon,
    String label,
    ColorScheme colorScheme,
  ) {
    return InkWell(
      onTap: () {
        MoonrakerInstance.moonrakerService.moveAxisRelative(axis, distance);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: colorScheme.onSurface),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeBtn(String axes, ColorScheme colorScheme) {
    return InkWell(
      onTap: () {
        MoonrakerInstance.moonrakerService.homeAxes(axes);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_rounded,
              size: 28,
              color: colorScheme.onPrimaryContainer,
            ),
            const SizedBox(height: 2),
            Text(
              'Home',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionInfo(ColorScheme colorScheme, TextTheme textTheme) {
    return Consumer<MoonrakerService>(
      builder: (context, service, _) {
        final printer = service.currentPrinter;
        final x = printer?.toolhead.x ?? 0.0;
        final y = printer?.toolhead.y ?? 0.0;
        final z = printer?.toolhead.z ?? 0.0;

        return Material(
          color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: colorScheme.secondary.withValues(alpha: 0.3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.my_location_rounded,
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Position',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.secondary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildAxisPos('X', x, colorScheme, textTheme),
                      const Divider(height: 12),
                      _buildAxisPos('Y', y, colorScheme, textTheme),
                      const Divider(height: 12),
                      _buildAxisPos('Z', z, colorScheme, textTheme),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    MoonrakerInstance.moonrakerService.homeAxes('x y z');
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Home All',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAxisPos(
    String axis,
    double value,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          axis,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.secondary,
          ),
        ),
        Text(
          '${value.toStringAsFixed(1)} mm',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
