import 'package:flutter/material.dart';
import 'package:poseidon_1/services/moonraker/instance/moonraker_instance.dart';
import 'package:poseidon_1/services/moonraker/types/macro.dart';

class LightWidget extends StatefulWidget {
  const LightWidget({super.key});

  @override
  State<LightWidget> createState() => _LightWidgetState();
}

class _LightWidgetState extends State<LightWidget> {
  bool partLightOn = false;
  bool frameLightOn = false;

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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildLightCard(
                  context,
                  colorScheme,
                  textTheme,
                  icon: Icons.lightbulb_rounded,
                  iconColor: Colors.amber,
                  name: 'Part Light',
                  containerColor: Colors.amber.withValues(alpha: 0.15),
                  onContainerColor: Colors.amber.shade700,
                  value: partLightOn,
                  onChanged: (val) {
                    setState(() {
                      partLightOn = val;
                    });
                    val
                        ? MoonrakerInstance.moonrakerService.runMacro(
                            Macro(name: 'PART_LIGHT_ON'),
                          )
                        : MoonrakerInstance.moonrakerService.runMacro(
                            Macro(name: 'PART_LIGHT_OFF'),
                          );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLightCard(
                  context,
                  colorScheme,
                  textTheme,
                  icon: Icons.highlight_rounded,
                  iconColor: Colors.indigo,
                  name: 'Frame Light',
                  containerColor: Colors.indigo.withValues(alpha: 0.15),
                  onContainerColor: Colors.indigo.shade400,
                  value: frameLightOn,
                  onChanged: (val) {
                    setState(() {
                      frameLightOn = val;
                    });
                    val
                        ? MoonrakerInstance.moonrakerService.runMacro(
                            Macro(name: 'FRAME_LIGHT_ON'),
                          )
                        : MoonrakerInstance.moonrakerService.runMacro(
                            Macro(name: 'FRAME_LIGHT_OFF'),
                          );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLightCard(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    required IconData icon,
    required Color iconColor,
    required String name,
    required Color containerColor,
    required Color onContainerColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Material(
      color: containerColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: onContainerColor.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: value ? iconColor : iconColor.withValues(alpha: 0.4),
                size: 64,
              ),
              const Spacer(),
              Text(
                name,
                style: textTheme.titleMedium?.copyWith(
                  color: onContainerColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: onContainerColor,
                inactiveThumbColor: onContainerColor.withValues(alpha: 0.5),
                inactiveTrackColor: containerColor,
                trackOutlineColor: WidgetStateProperty.resolveWith((states) {
                  if (!states.contains(WidgetState.selected)) {
                    return onContainerColor.withValues(alpha: 0.3);
                  }
                  return Colors.transparent;
                }),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
