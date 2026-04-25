import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:poseidon_1/services/moonraker/discovery_service.dart';
import 'package:poseidon_1/services/moonraker/types/current_print_job.dart';
import 'package:poseidon_1/services/moonraker/types/fan.dart';
import 'package:poseidon_1/services/moonraker/types/heater.dart';
import 'package:poseidon_1/services/moonraker/types/macro.dart';
import 'package:poseidon_1/services/moonraker/types/print_job.dart';
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
  static bool _shouldReconnect = true;

  static String? _lastKnownIP;
  static int? _lastKnownPort;

  static WebSocketChannel? _channel;
  static Peer? _rpc;

  Future<void> connectPrinter(MoonrakerDNSInstance instance) async {
    if (_isConnecting) {
      return;
    }

    _shouldReconnect = true;
    _isConnecting = true;
    _lastKnownIP = instance.ip;
    _lastKnownPort = instance.port;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    await _disposeConnection();

    final Uri wsURI = Uri.parse(
      'ws://${instance.ip}:${instance.port}/websocket',
    );
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
      print('Connected to Moonraker at ${instance.ip}:${instance.port}');
      DiscoveryService.saveInstance(instance);
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
    if (!_shouldReconnect) {
      return;
    }

    if ((_reconnectTimer?.isActive ?? false) || _isConnecting || _isConnected) {
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
      unawaited(
        connectPrinter(
          MoonrakerDNSInstance(ip: _lastKnownIP!, port: _lastKnownPort!),
        ),
      );
    });
  }

  void _handleDisconnect() {
    _isConnected = false;
    if (!_shouldReconnect) {
      return;
    }

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
    _shouldReconnect = false;
    _isConnected = false;
    _isConnecting = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    printer = null;
    await _disposeConnection();
  }

  bool get _hasActiveConnection => _rpc != null && _isConnected;

  Future<bool> _waitForConnectionOrShutdown() async {
    while (!_hasActiveConnection && _shouldReconnect) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return _hasActiveConnection;
  }

  PrinterState _fallbackPrinterState() =>
      printer?.state ?? PrinterState.startup;

  Heater _fallbackExtruder() {
    return printer?.extruder ??
        Heater(
          name: HeaterType.extruder,
          actualTemp: 0,
          targetTemp: 0,
          power: 0,
        );
  }

  Heater _fallbackHeaterBed() {
    return printer?.heaterBed ??
        Heater(
          name: HeaterType.heaterBed,
          actualTemp: 0,
          targetTemp: 0,
          power: 0,
        );
  }

  Toolhead _fallbackToolhead() {
    return printer?.toolhead ?? Toolhead(x: 0, y: 0, z: 0, e: 0, homedAxes: '');
  }

  Fan _fallbackFan() {
    return printer?.fan ?? Fan(speed: 0.0);
  }

  CurrentPrintJob _fallbackCurrentPrintJob() {
    return printer?.currentPrintJob ??
        CurrentPrintJob(
          filePath: '',
          totalDuration: 0,
          printDuration: 0,
          filamentUsed: 0,
          state: CurrentPrintJobState.standby,
          message: '',
          totalLayers: null,
          currentLayer: null,
        );
  }

  Future<PrinterState> getPrinterState() async {
    final connected = await _waitForConnectionOrShutdown();
    if (!connected) {
      return _fallbackPrinterState();
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
      return _fallbackPrinterState();
    }
  }

  Future<Heater> getExtruderStatus() async {
    final connected = await _waitForConnectionOrShutdown();
    if (!connected) {
      return _fallbackExtruder();
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
      return _fallbackExtruder();
    }
  }

  Future<Heater> getHeaterBedStatus() async {
    final connected = await _waitForConnectionOrShutdown();
    if (!connected) {
      return _fallbackHeaterBed();
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
      return _fallbackHeaterBed();
    }
  }

  Future<Toolhead> getToolheadStatus() async {
    final connected = await _waitForConnectionOrShutdown();
    if (!connected) {
      return _fallbackToolhead();
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
      return _fallbackToolhead();
    }
  }

  Future<Fan> getFanStatus() async {
    final connected = await _waitForConnectionOrShutdown();
    if (!connected) {
      return _fallbackFan();
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
      return _fallbackFan();
    }
  }

  Future<List<Macro>> getMacroListFromObjects(List<String> objects) async {
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
      return <Macro>[];
    }
  }

  Future<List<PrintJob>> getLatestPrintJobs() async {
    final connected = await _waitForConnectionOrShutdown();
    if (!connected) {
      return printer?.printJobs ?? <PrintJob>[];
    }

    try {
      final response = await _rpc!
          .sendRequest('server.history.list')
          .timeout(const Duration(seconds: 4));

      final rawJobs = (response['jobs'] ?? response['status']?['print_jobs']);
      if (rawJobs is! List) {
        throw Exception('Unexpected history response format');
      }

      return List<PrintJob>.from(
        rawJobs
            .whereType<Map>()
            .map((e) => PrintJob.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
    } catch (error) {
      print('Failed to get print jobs: $error');
      return printer?.printJobs ?? <PrintJob>[];
    }
  }

  Future<void> refreshLatestPrintJobs() async {
    final printJobs = await getLatestPrintJobs();
    if (printer != null) {
      printer!.printJobs = printJobs;
      notifyListeners();
    }
  }

  Future<CurrentPrintJob> getCurrentPrintJob() async {
    final connected = await _waitForConnectionOrShutdown();
    if (!connected) {
      return _fallbackCurrentPrintJob();
    }

    try {
      final response = await _rpc!
          .sendRequest('printer.objects.query', {
            'objects': {
              'print_stats': [
                'state',
                'filename',
                'total_duration',
                'print_duration',
                'filament_used',
                'message',
                'info',
              ],
            },
          })
          .timeout(const Duration(seconds: 4));
      final Map<String, dynamic> printStatsJson = {
        ...response['status']['print_stats'],
      };
      return CurrentPrintJob.fromJson(printStatsJson);
    } catch (error) {
      print('Failed to get current print job: $error');
      return _fallbackCurrentPrintJob();
    }
  }

  Future<List<String>> getObjectList() async {
    final connected = await _waitForConnectionOrShutdown();
    if (!connected) {
      return printer?.objects ?? <String>[];
    }

    try {
      final response = await _rpc!
          .sendRequest('printer.objects.list')
          .timeout(const Duration(seconds: 4));
      return List<String>.from(response['objects']);
    } catch (error) {
      print('Failed to get object list: $error');
      return printer?.objects ?? <String>[];
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
        getLatestPrintJobs(),
        getObjectList(),
        getCurrentPrintJob(),
      ]);
      final state = results[0] as PrinterState;
      final extruder = results[1] as Heater;
      final heaterBed = results[2] as Heater;
      final toolhead = results[3] as Toolhead;
      final fan = results[4] as Fan;
      final printJobs = results[5] as List<PrintJob>;
      final objects = results[6] as List<String>;
      final macros = await getMacroListFromObjects(objects);
      final currentPrintJob = results[7] as CurrentPrintJob;

      printer = Printer(
        state: state,
        extruder: extruder,
        heaterBed: heaterBed,
        toolhead: toolhead,
        fan: fan,
        macros: macros,
        objects: objects,
        printJobs: printJobs,
        currentPrintJob: currentPrintJob,
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
        _updateCurrentPrintJobFromStatus(status);
      });
      final response = await _rpc!
          .sendRequest('printer.objects.subscribe', {
            'objects': {
              'extruder': ['temperature', 'target', 'power'],
              'heater_bed': ['temperature', 'target', 'power'],
              'toolhead': ['position', 'homed_axes'],
              'print_stats': [
                'state',
                'filename',
                'total_duration',
                'print_duration',
                'filament_used',
                'message',
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
      final Map<String, dynamic> printStatsJson = {
        ...response['status']['print_stats'],
      };
      final Map<String, dynamic> fanJson = {...response['status']['fan']};

      print('response: $response');
      printer?.extruder = Heater.fromJson(extruderJson);
      printer?.heaterBed = Heater.fromJson(heaterBedJson);
      printer?.toolhead = Toolhead.fromJson(toolheadJson);
      printer?.currentPrintJob = CurrentPrintJob.fromJson(printStatsJson);
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

  void _updateCurrentPrintJobFromStatus(Map<String, dynamic> status) {
    if (printer == null) {
      return;
    }

    var didChange = false;

    if (status['print_stats'] is Map) {
      final printStatsPatch = Map<String, dynamic>.from(
        status['print_stats'] as Map,
      );
      final currentPrintJob = printer!.currentPrintJob;
      final currentInfo = <String, dynamic>{
        if (currentPrintJob.totalLayers != null)
          'total_layer': currentPrintJob.totalLayers,
        if (currentPrintJob.currentLayer != null)
          'current_layer': currentPrintJob.currentLayer,
      };

      final mergedInfo = <String, dynamic>{...currentInfo};
      if (printStatsPatch['info'] is Map) {
        mergedInfo.addAll(
          Map<String, dynamic>.from(printStatsPatch['info'] as Map),
        );
      }
      if (printStatsPatch['total_layer'] != null) {
        mergedInfo['total_layer'] = printStatsPatch['total_layer'];
      }
      if (printStatsPatch['current_layer'] != null) {
        mergedInfo['current_layer'] = printStatsPatch['current_layer'];
      }
      if (printStatsPatch['total_layers'] != null) {
        mergedInfo['total_layers'] = printStatsPatch['total_layers'];
      }
      if (printStatsPatch['current_layers'] != null) {
        mergedInfo['current_layers'] = printStatsPatch['current_layers'];
      }

      final printStatsJson = {
        'filename':
            (printStatsPatch['filename'] as String?) ??
            currentPrintJob.filePath,
        'state':
            (printStatsPatch['state'] as String?) ??
            currentPrintJob.state.toString().split('.').last,
        'total_duration':
            (printStatsPatch['total_duration'] as num?)?.toDouble() ??
            currentPrintJob.totalDuration,
        'print_duration':
            (printStatsPatch['print_duration'] as num?)?.toDouble() ??
            currentPrintJob.printDuration,
        'filament_used':
            (printStatsPatch['filament_used'] as num?)?.toDouble() ??
            currentPrintJob.filamentUsed,
        'message':
            (printStatsPatch['message'] as String?) ?? currentPrintJob.message,
        'info': mergedInfo,
      };
      printer?.currentPrintJob = CurrentPrintJob.fromJson(printStatsJson);
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

  void clearCurrentPrintSelection() {
    if (printer == null) {
      return;
    }

    printer!.currentPrintJob = CurrentPrintJob(
      filePath: '',
      totalDuration: 0,
      printDuration: 0,
      filamentUsed: 0,
      state: CurrentPrintJobState.standby,
      message: '',
      totalLayers: null,
      currentLayer: null,
    );

    notifyListeners();
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

  void deleteFile(String path) {
    if (_rpc == null || !_isConnected) {
      print('Not connected to Moonraker');
      return;
    }

    try {
      _rpc!.sendRequest('server.files.delete_file', {'path': path}).catchError((
        error,
      ) {
        print('Failed to delete file: $error');
      });
    } catch (error) {
      print('Failed to delete file: $error');
    }
  }

  void homeAxes(String axes) {
    if (_rpc == null || !_isConnected) {
      print('Not connected to Moonraker');
      return;
    }

    try {
      _rpc!
          .sendRequest('printer.gcode.script', {'script': 'G28 $axes'})
          .catchError((error) {
            print('Failed to home axes: $error');
          });
    } catch (error) {
      print('Failed to home axes: $error');
    }
  }

  void moveAxisRelative(String axis, double distance) {
    if (_rpc == null || !_isConnected) {
      print('Not connected to Moonraker');
      return;
    }

    try {
      _rpc!
          .sendRequest('printer.gcode.script', {
            'script':
                '_CLIENT_LINEAR_MOVE ${axis.toUpperCase()}=${distance} F=7800',
          })
          .catchError((error) {
            print('Failed to move axis: $error');
          });
    } catch (error) {
      print('Failed to move axis: $error');
    }
  }

  void setExtruderTemperature(double temperature) {
    if (_rpc == null || !_isConnected) {
      print('Not connected to Moonraker');
      return;
    }
    try {
      _rpc!
          .sendRequest('printer.gcode.script', {
            'script': 'M104 S${temperature.toStringAsFixed(1)}',
          })
          .catchError((error) {
            print('Failed to set extruder temperature: $error');
          });
    } catch (error) {
      print('Failed to set extruder temperature: $error');
    }
  }

  void setBedTemperature(double temperature) {
    if (_rpc == null || !_isConnected) {
      print('Not connected to Moonraker');
      return;
    }
    try {
      _rpc!
          .sendRequest('printer.gcode.script', {
            'script': 'M140 S${temperature.toStringAsFixed(1)}',
          })
          .catchError((error) {
            print('Failed to set bed temperature: $error');
          });
    } catch (error) {
      print('Failed to set bed temperature: $error');
    }
  }

  ImageProvider getThumbnail(String path) {
    if (_rpc == null || !_isConnected) {
      print('Not connected to Moonraker');
      return const AssetImage('assets/placeholder_thumbnail.png');
    }

    final normalizedPath = path.trim().replaceAll('\\', '/');
    final noLeadingSlash = normalizedPath.startsWith('/')
        ? normalizedPath.substring(1)
        : normalizedPath;

    final uri = Uri(
      scheme: 'http',
      host: _lastKnownIP!,
      port: _lastKnownPort!,
      pathSegments: ['server', 'files', 'gcodes', ...noLeadingSlash.split('/')],
    );
    return NetworkImage(uri.toString());
  }
}
