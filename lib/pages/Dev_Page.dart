import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:poseidon_1/services/moonraker/instance/moonraker_instance.dart';
import 'package:poseidon_1/services/moonraker/moonraker_service.dart';
import 'package:poseidon_1/services/moonraker/types/current_print_job.dart';
import 'package:provider/provider.dart';

class DevPage extends StatelessWidget {
  const DevPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text('Moonraker Demo'),
            ButtonM3E(
              label: Text('Reprint recent print'),
              onPressed: () {
                MoonrakerInstance.moonrakerService.startPrint(
                  MoonrakerInstance
                          .moonrakerService
                          .currentPrinter
                          ?.printJobs
                          .first
                          .filePath ??
                      '',
                );
              },
            ),

            Consumer<MoonrakerService>(
              builder: (context, service, child) {
                final extruderPower =
                    ((service.currentPrinter?.extruder.power ?? 0.0) * 100)
                        .toInt();
                final heaterBedPower =
                    ((service.currentPrinter?.heaterBed.power ?? 0.0) * 100)
                        .toInt();
                final fanSpeedPercent =
                    ((service.currentPrinter?.fan.speed ?? 0.0) * 100).toInt();
                return Column(
                  children: [
                    Text('Extruder Status'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                      children: [
                        Text(
                          'Temp: ${service.currentPrinter?.extruder.actualTemp.toStringAsFixed(1) ?? 'N/A'}',
                        ),
                        Text(
                          'Target: ${service.currentPrinter?.extruder.targetTemp.toStringAsFixed(1) ?? 'N/A'}',
                        ),
                        Text('Power: $extruderPower%'),
                      ],
                    ),
                    Text('Heater Bed Status'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          'Temp: ${service.currentPrinter?.heaterBed.actualTemp.toStringAsFixed(1) ?? 'N/A'}',
                        ),
                        Text(
                          'Target: ${service.currentPrinter?.heaterBed.targetTemp.toStringAsFixed(1) ?? 'N/A'}',
                        ),
                        Text('Power: $heaterBedPower%'),
                      ],
                    ),
                    Text('Toolhead Status'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          'X: ${service.currentPrinter?.toolhead.x.toStringAsFixed(2) ?? 'N/A'}',
                        ),
                        Text(
                          'Y: ${service.currentPrinter?.toolhead.y.toStringAsFixed(2) ?? 'N/A'}',
                        ),
                        Text(
                          'Z: ${service.currentPrinter?.toolhead.z.toStringAsFixed(2) ?? 'N/A'}',
                        ),
                      ],
                    ),
                    Text('Fan Status'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [Text('Speed: $fanSpeedPercent%')],
                    ),
                    if (service.currentPrinter?.currentPrintJob.state ==
                        CurrentPrintJobState.printing) ...[
                      Text('Current Print Job'),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            service.currentPrinter?.currentPrintJob.filePath
                                    .split('/')
                                    .last ??
                                'No current print job',
                          ),
                          Text(
                            'Filament Used: ${service.currentPrinter?.currentPrintJob.filamentUsed.toStringAsFixed(2) ?? 'N/A'} mm',
                          ),
                          Text(
                            'Print Duration: ${service.currentPrinter?.currentPrintJob.printDuration.toStringAsFixed(1) ?? 'N/A'} s',
                          ),
                        ],
                      ),
                    ],
                    Text(
                      'MACRO: ${service.currentPrinter?.macros.first.name ?? 'N/A'}',
                    ),
                  ],
                );
              },
            ),

            Column(
              children: [
                Text('Loading Indicator'),
                SizedBox(height: 16),
                LoadingIndicatorM3E(),
              ],
            ),
            Column(
              children: [
                Text('Circular Progress Indicator - flat'),
                SizedBox(height: 16),
                CircularProgressIndicatorM3E(
                  size: CircularProgressM3ESize.m,
                  shape: ProgressM3EShape.flat,
                  value: 50,
                ),
              ],
            ),
            Column(
              children: [
                Text('Circular Progress Indicator - wavy'),
                SizedBox(height: 16),
                CircularProgressIndicatorM3E(
                  size: CircularProgressM3ESize.m,
                  shape: ProgressM3EShape.wavy,
                ),
              ],
            ),
            Column(
              children: [
                Text('Linear Progress Indicator - wavy'),
                SizedBox(height: 16),
                LinearProgressIndicatorM3E(
                  value: 50,
                  size: LinearProgressM3ESize.m,
                  shape: ProgressM3EShape.wavy,
                ),
              ],
            ),
            Column(
              children: [
                Text('Linear Progress Indicator - flat'),
                SizedBox(height: 16),
                LinearProgressIndicatorM3E(
                  value: 50,
                  size: LinearProgressM3ESize.m,
                  shape: ProgressM3EShape.flat,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
