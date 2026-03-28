import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:poseidon_1/services/moonraker/types/fan.dart';
import 'package:poseidon_1/services/moonraker/types/heater.dart';
import 'package:poseidon_1/services/moonraker/types/macro.dart';
import 'package:poseidon_1/services/moonraker/types/printer.dart';
import 'package:poseidon_1/services/moonraker/types/toolhead.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class MoonrakerService extends ChangeNotifier {
  static Printer? printer;

  Printer? get currentPrinter => printer;

  static int _retryCount = 0;
  static Timer? _reconnectTimer;
  static bool _isConnecting = false;
  static bool _isConnected = false;

  static String? _lastKnownIP;
  static int? _lastKnownPort;

  static WebSocketChannel? _channel;
  static Peer? _rpc;

  //TODO: Autodiscover printer on local network
  Future<void> connectPrinter({required String ip, required int port}) async {
    if (_isConnecting) {
      return;
    }

    _isConnecting = true;
    _lastKnownIP = ip;
    _lastKnownPort = port;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    await _disposeConnection();

    final Uri wsURI = Uri.parse('ws://$ip:$port/websocket');
    try {
      final channel = WebSocketChannel.connect(wsURI);
      final rpc = Peer(channel.cast<String>());

      _channel = channel;
      _rpc = rpc;

      unawaited(
        rpc
            .listen()
            .catchError((error) {
              print('RPC Error: $error');
            })
            .whenComplete(() {
              print('RPC connection closed');
              _handleDisconnect();
            }),
      );

      // Verify the connection with a quick RPC round trip.
      await rpc.sendRequest('server.info').timeout(const Duration(seconds: 3));

      _retryCount = 0;
      _isConnected = true;
      print('Connected to Moonraker at $ip:$port');
      await newPrinter();
      subscribeToObjects();
    } catch (error) {
      _isConnected = false;
      print('Connection failed: $error');
      await _disposeConnection();
      _scheduleReconnect();
    } finally {
      _isConnecting = false;
    }
  }

  void _scheduleReconnect() {
    if ((_reconnectTimer?.isActive ?? false) || _isConnecting) {
      return;
    }

    if (_lastKnownIP == null || _lastKnownPort == null) {
      return;
    }

    _retryCount++;
    _isConnected = false;

    final delay = Duration(seconds: min(30, 1 << (_retryCount - 1)));
    print('Reconnecting in ${delay.inSeconds}s...');

    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      unawaited(connectPrinter(ip: _lastKnownIP!, port: _lastKnownPort!));
    });
  }

  void _handleDisconnect() {
    _isConnected = false;
    unawaited(
      _disposeConnection().whenComplete(() {
        _scheduleReconnect();
      }),
    );
  }

  Future<void> _disposeConnection() async {
    final rpc = _rpc;
    final channel = _channel;

    _rpc = null;
    _channel = null;

    try {
      await rpc?.close();
    } catch (_) {}

    try {
      await channel?.sink.close();
    } catch (_) {}
  }

  Future<void> disconnect() async {
    _isConnected = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    printer = null;
    await _disposeConnection();
  }

  Future<PrinterState> getPrinterState() async {
    if (_rpc == null || !_isConnected) {
      throw Exception('Not connected to Moonraker');
    }

    try {
      final response = await _rpc!
          .sendRequest('printer.info')
          .timeout(const Duration(seconds: 4));
      return PrinterState.values.firstWhere(
        (e) => e.toString() == 'PrinterState.' + response['state'],
      );
    } catch (error) {
      print('Failed to get printer state: $error');
      rethrow;
    }
  }

  Future<Heater> getExtruderStatus() async {
    if (_rpc == null || !_isConnected) {
      throw Exception('Not connected to Moonraker');
    }

    try {
      final response = await _rpc!
          .sendRequest('printer.objects.query', {
            'objects': {
              'extruder': ['temperature', 'target', 'power'],
            },
          })
          .timeout(const Duration(seconds: 4));
      final Map<String, dynamic> extruderJson = {
        ...response['status']['extruder'],
        'name': 'extruder',
      };
      return Heater.fromJson(extruderJson);
    } catch (error) {
      print('Failed to get extruder status: $error');
      rethrow;
    }
  }

  Future<Heater> getHeaterBedStatus() async {
    if (_rpc == null || !_isConnected) {
      throw Exception('Not connected to Moonraker');
    }

    try {
      final response = await _rpc!
          .sendRequest('printer.objects.query', {
            'objects': {
              'heater_bed': ['temperature', 'target', 'power'],
            },
          })
          .timeout(const Duration(seconds: 4));
      final Map<String, dynamic> heaterBedJson = {
        ...response['status']['heater_bed'],
        'name': 'heaterBed',
      };
      return Heater.fromJson(heaterBedJson);
    } catch (error) {
      print('Failed to get heater bed status: $error');
      rethrow;
    }
  }

  Future<Toolhead> getToolheadStatus() async {
    if (_rpc == null || !_isConnected) {
      throw Exception('Not connected to Moonraker');
    }

    try {
      final response = await _rpc!
          .sendRequest('printer.objects.query', {
            'objects': {
              'toolhead': ['position', 'homed_axes'],
            },
          })
          .timeout(const Duration(seconds: 4));
      return Toolhead.fromJson(response['status']['toolhead']);
    } catch (error) {
      print('Failed to get toolhead status: $error');
      rethrow;
    }
  }

  Future<Fan> getFanStatus() async {
    if (_rpc == null || !_isConnected) {
      throw Exception('Not connected to Moonraker');
    }

    try {
      final response = await _rpc!
          .sendRequest('printer.objects.query', {
            'objects': {
              'fan': ['speed'],
            },
          })
          .timeout(const Duration(seconds: 4));
      return Fan.fromJson(response['status']['fan']);
    } catch (error) {
      print('Failed to get fan status: $error');
      rethrow;
    }
  }

  Future<List<Macro>> getMacroListFromObjects(List<String> objects) async {
    if (_rpc == null || !_isConnected) {
      throw Exception('Not connected to Moonraker');
    }

    try {
      const prefix = 'gcode_macro ';
      final macros = <Macro>[];

      for (final objectName in objects) {
        if (!objectName.startsWith(prefix)) {
          continue;
        }

        final macroName = objectName.substring(prefix.length).trim();
        if (macroName.isEmpty) {
          continue;
        }

        macros.add(Macro(name: macroName));
      }

      return macros;
    } catch (error) {
      print('Failed to get macro list: $error');
      rethrow;
    }
  }

  Future<List<String>> getObjectList() async {
    if (_rpc == null || !_isConnected) {
      throw Exception('Not connected to Moonraker');
    }

    try {
      final response = await _rpc!
          .sendRequest('printer.objects.list')
          .timeout(const Duration(seconds: 4));
      return List<String>.from(response['objects']);
    } catch (error) {
      print('Failed to get object list: $error');
      rethrow;
    }
  }

  Future<void> identifyPoseidon() async {
    if (_rpc == null || !_isConnected) {
      print('Not connected to Moonraker');
      return;
    }

    try {
      await _rpc!
          .sendRequest('server.connection.identify', {
            'client_name': 'Poseidon-1',
            'version': '0.0.1',
            'type': 'display',
            'url': 'https://github.com/Choccy-vr/Poseidon-1',
          })
          .timeout(const Duration(seconds: 4));
      print('Identified Poseidon-1 to Moonraker');
    } catch (error) {
      print('Failed to identify Poseidon-1: $error');
    }
  }

  Future<void> newPrinter() async {
    print('fetching initial printer status...');
    try {
      final results = await Future.wait([
        //TODO: batch these into a single request
        getPrinterState(),
        getExtruderStatus(),
        getHeaterBedStatus(),
        getToolheadStatus(),
        getFanStatus(),
        getObjectList(),
      ]);
      final state = results[0] as PrinterState;
      final extruder = results[1] as Heater;
      final heaterBed = results[2] as Heater;
      final toolhead = results[3] as Toolhead;
      final fan = results[4] as Fan;
      final objects = results[5] as List<String>;
      final macros = await getMacroListFromObjects(objects);

      printer = Printer(
        state: state,
        extruder: extruder,
        heaterBed: heaterBed,
        toolhead: toolhead,
        fan: fan,
        macros: macros,
        objects: objects,
      );
      identifyPoseidon();
      notifyListeners();
    } catch (error) {
      print('Failed to initialize printer: $error');
    }
  }

  Future<void> subscribeToObjects() async {
    if (_rpc == null || !_isConnected) {
      print('Not connected to Moonraker');
      return;
    }
    if (printer == null) {
      print('Printer not available');
      return;
    }

    try {
      _rpc!.registerMethod('notify_status_update', (params) {
        final dynamic rawValue = params.value;
        Map<String, dynamic>? status;

        if (rawValue is List && rawValue.isNotEmpty && rawValue.first is Map) {
          status = Map<String, dynamic>.from(rawValue.first as Map);
        } else if (rawValue is Map && rawValue['status'] is Map) {
          status = Map<String, dynamic>.from(rawValue['status'] as Map);
        }

        if (status == null) {
          return;
        }

        print('status update: $status');

        _updateHeatersFromStatus(status);
        _updateToolheadFromStatus(status);
        _updateFanFromStatus(status);
      });
      final response = await _rpc!
          .sendRequest('printer.objects.subscribe', {
            'objects': {
              'extruder': ['temperature', 'target', 'power'],
              'heater_bed': ['temperature', 'target', 'power'],
              'toolhead': ['position', 'homed_axes'],
              'print_stats': [
                'filename',
                'print_duration',
                'filament_used',
                'state',
                'info',
              ],
              'fan': ['speed'],
            },
          })
          .timeout(const Duration(seconds: 4));
      final Map<String, dynamic> extruderJson = {
        ...response['status']['extruder'],
        'name': 'extruder',
      };
      final Map<String, dynamic> heaterBedJson = {
        ...response['status']['heater_bed'],
        'name': 'heaterBed',
      };
      final Map<String, dynamic> toolheadJson = {
        ...response['status']['toolhead'],
      };
      final Map<String, dynamic> fanJson = {...response['status']['fan']};

      print('response: $response');
      printer?.extruder = Heater.fromJson(extruderJson);
      printer?.heaterBed = Heater.fromJson(heaterBedJson);
      printer?.toolhead = Toolhead.fromJson(toolheadJson);
      printer?.fan = Fan.fromJson(fanJson);
      notifyListeners();
    } catch (error) {
      print('Failed to subscribe to objects: $error');
    }
  }

  void _updateHeatersFromStatus(Map<String, dynamic> status) {
    if (printer == null) {
      return;
    }

    var didChange = false;

    if (status['extruder'] is Map) {
      final extruderPatch = Map<String, dynamic>.from(
        status['extruder'] as Map,
      );
      final extruderJson = {
        'name': 'extruder',
        'temperature':
            (extruderPatch['temperature'] as num?)?.toDouble() ??
            printer!.extruder.actualTemp,
        'target':
            (extruderPatch['target'] as num?)?.toDouble() ??
            printer!.extruder.targetTemp,
        'power':
            (extruderPatch['power'] as num?)?.toDouble() ??
            printer!.extruder.power,
      };
      printer?.extruder = Heater.fromJson(extruderJson);
      didChange = true;
    }

    if (status['heater_bed'] is Map) {
      final heaterBedPatch = Map<String, dynamic>.from(
        status['heater_bed'] as Map,
      );
      final heaterBedJson = {
        'name': 'heaterBed',
        'temperature':
            (heaterBedPatch['temperature'] as num?)?.toDouble() ??
            printer!.heaterBed.actualTemp,
        'target':
            (heaterBedPatch['target'] as num?)?.toDouble() ??
            printer!.heaterBed.targetTemp,
        'power':
            (heaterBedPatch['power'] as num?)?.toDouble() ??
            printer!.heaterBed.power,
      };
      printer?.heaterBed = Heater.fromJson(heaterBedJson);
      didChange = true;
    }

    if (didChange) {
      notifyListeners();
    }
  }

  void _updateToolheadFromStatus(Map<String, dynamic> status) {
    if (printer == null) {
      return;
    }

    var didChange = false;

    if (status['toolhead'] is Map) {
      final toolheadPatch = Map<String, dynamic>.from(
        status['toolhead'] as Map,
      );
      final currentToolhead = printer!.toolhead;
      final currentPosition = <double>[
        currentToolhead.x,
        currentToolhead.y,
        currentToolhead.z,
        currentToolhead.e,
      ];

      var position = currentPosition;
      final rawPosition = toolheadPatch['position'];
      if (rawPosition is List) {
        final parsedPosition = rawPosition
            .whereType<num>()
            .map((value) => value.toDouble())
            .toList();
        if (parsedPosition.length == 4) {
          position = parsedPosition;
        }
      }

      final toolheadJson = {
        'position': position,
        'homed_axes':
            (toolheadPatch['homed_axes'] as String?) ??
            currentToolhead.homedAxes,
      };
      printer?.toolhead = Toolhead.fromJson(toolheadJson);
      didChange = true;
    }
    if (didChange) {
      notifyListeners();
    }
  }

  void _updateFanFromStatus(Map<String, dynamic> status) {
    if (printer == null) {
      return;
    }

    var didChange = false;

    if (status['fan'] is Map) {
      final fanPatch = Map<String, dynamic>.from(status['fan'] as Map);
      final currentFan = printer!.fan;

      final fanJson = {
        'speed': (fanPatch['speed'] as num?)?.toDouble() ?? currentFan.speed,
      };
      printer?.fan = Fan.fromJson(fanJson);
      didChange = true;
    }

    if (didChange) {
      notifyListeners();
    }
  }

  void emergencyStop() {
    if (_rpc == null || !_isConnected) {
      print('Not connected to Moonraker');
      return;
    }

    _rpc!.sendRequest('printer.emergency_stop').catchError((error) {
      print('Failed to send emergency stop: $error');
    });
  }

  void executeMacro(Macro macro) {
    if (_rpc == null || !_isConnected) {
      print('Not connected to Moonraker');
      return;
    }

    _rpc!
        .sendRequest('printer.gcode.script', {'script': macro.name})
        .catchError((error) {
          print('Failed to execute macro ${macro.name}: $error');
        });
  }

  void startPrint(String path) {
    if (_rpc == null || !_isConnected) {
      print('Not connected to Moonraker');
      return;
    }

    try {
      _rpc!.sendRequest('printer.print.start', {'filename': path}).catchError((
        error,
      ) {
        print('Failed to start print: $error');
      });
    } catch (error) {
      print('Failed to start print: $error');
    }

    //TODO: handle response and update printer state accordingly
  }

  void pausePrint() {
    if (_rpc == null || !_isConnected) {
      print('Not connected to Moonraker');
      return;
    }

    try {
      _rpc!.sendRequest('printer.print.pause').catchError((error) {
        print('Failed to pause print: $error');
      });
    } catch (error) {
      print('Failed to pause print: $error');
    }
  }

  void resumePrint() {
    if (_rpc == null || !_isConnected) {
      print('Not connected to Moonraker');
      return;
    }

    try {
      _rpc!.sendRequest('printer.print.resume').catchError((error) {
        print('Failed to resume print: $error');
      });
    } catch (error) {
      print('Failed to resume print: $error');
    }
  }

  void cancelPrint() {
    if (_rpc == null || !_isConnected) {
      print('Not connected to Moonraker');
      return;
    }

    try {
      _rpc!.sendRequest('printer.print.cancel').catchError((error) {
        print('Failed to cancel print: $error');
      });
    } catch (error) {
      print('Failed to cancel print: $error');
    }
  }

  void firmwareRestart() {
    if (_rpc == null || !_isConnected) {
      print('Not connected to Moonraker');
      return;
    }

    try {
      _rpc!.sendRequest('printer.firmware_restart').catchError((error) {
        print('Failed to restart firmware: $error');
      });
    } catch (error) {
      print('Failed to restart firmware: $error');
    }
  }

  void hostRestart() {
    if (_rpc == null || !_isConnected) {
      print('Not connected to Moonraker');
      return;
    }

    try {
      _rpc!.sendRequest('printer.restart').catchError((error) {
        print('Failed to restart host: $error');
      });
    } catch (error) {
      print('Failed to restart host: $error');
    }
  }
}
