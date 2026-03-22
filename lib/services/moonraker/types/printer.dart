import 'package:poseidon_1/services/moonraker/types/fan.dart';
import 'package:poseidon_1/services/moonraker/types/heater.dart';
import 'package:poseidon_1/services/moonraker/types/macro.dart';
import 'package:poseidon_1/services/moonraker/types/print_job.dart';
import 'package:poseidon_1/services/moonraker/types/toolhead.dart';

class Printer {
  PrinterState state;
  Heater extruder;
  Heater heaterBed;
  Heater heaterOutterBed;
  Toolhead toolhead;
  PrintJob job;
  List<Fan> fans;
  List<Macro> macros;
  String message;

  Printer({
    required this.state,
    required this.extruder,
    required this.heaterBed,
    required this.heaterOutterBed,
    required this.toolhead,
    required this.job,
    required this.fans,
    required this.macros,
    required this.message,
  });

  factory Printer.fromJson(Map<String, dynamic> json) {
    return Printer(
      state: PrinterState.values.firstWhere(
        (e) => e.toString() == 'PrinterState.' + json['state'],
      ),
      extruder: Heater.fromJson(json['extruder']),
      heaterBed: Heater.fromJson(json['heater_bed']),
      heaterOutterBed: Heater.fromJson(json['heater_outter_bed']),
      toolhead: Toolhead.fromJson(json['toolhead']),
      job: PrintJob.fromJson(json['job']),
      fans: List<Fan>.from(json['fans'].map((x) => Fan.fromJson(x))),
      macros: List<Macro>.from(json['macros'].map((x) => Macro.fromJson(x))),
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'state': state.toString().split('.').last,
      'extruder': extruder.toJson(),
      'heater_bed': heaterBed.toJson(),
      'heater_outter_bed': heaterOutterBed.toJson(),
      'toolhead': toolhead.toJson(),
      'job': job.toJson(),
      'fans': List<dynamic>.from(fans.map((x) => x.toJson())),
      'macros': List<dynamic>.from(macros.map((x) => x.toJson())),
      'message': message,
    };
  }
}

enum PrinterState {
  disconnected,
  standby,
  ready,
  busy,
  printing,
  paused,
  error,
}
