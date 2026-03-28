import 'package:poseidon_1/services/moonraker/types/fan.dart';
import 'package:poseidon_1/services/moonraker/types/heater.dart';
import 'package:poseidon_1/services/moonraker/types/macro.dart';
import 'package:poseidon_1/services/moonraker/types/print_job.dart';
import 'package:poseidon_1/services/moonraker/types/toolhead.dart';

class Printer {
  PrinterState state;
  Heater extruder;
  Heater heaterBed;
  Toolhead toolhead;
  Fan fan;
  List<Macro> macros;
  List<PrintJob> printJobs;
  List<String> objects;
  String? message;

  Printer({
    required this.state,
    required this.extruder,
    required this.heaterBed,
    required this.toolhead,
    required this.fan,
    required this.macros,
    required this.printJobs,
    required this.objects,
    this.message,
  });

  factory Printer.fromJson(Map<String, dynamic> json) {
    return Printer(
      state: PrinterState.values.firstWhere(
        (e) => e.toString() == 'PrinterState.' + json['state'],
      ),
      extruder: Heater.fromJson(json['extruder']),
      heaterBed: Heater.fromJson(json['heater_bed']),
      toolhead: Toolhead.fromJson(json['toolhead']),
      fan: Fan.fromJson(json['fan']),
      macros: List<Macro>.from(
        (json['macros'] as List).map((e) => Macro.fromJson(e)).toList(),
      ),

      printJobs: List<PrintJob>.from(
        (json['print_jobs'] as List).map((e) => PrintJob.fromJson(e)).toList(),
      ),

      objects: List<String>.from(json['objects']),
      message: json['message'],
    );
  }
}

enum PrinterState { ready, startup, error, shutdown }
