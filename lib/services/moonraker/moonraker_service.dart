import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:poseidon_1/services/moonraker/types/heater.dart';
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

  static String? _lastKnownIP;
  static int? _lastKnownPort;

  static WebSocketChannel? _channel;
  static Peer? _rpc;

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
      subscribeHeaters();
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

  Future<PrintJob> getPrintJobStatus() async {
    if (_rpc == null || !_isConnected) {
      throw Exception('Not connected to Moonraker');
    }

    try {
      final response = await _rpc!
          .sendRequest('printer.objects.query', {
            'objects': {
              'print_stats': [
                'filename',
                'progress',
                'time_elapsed',
                'time_remaining',
              ],
            },
          })
          .timeout(const Duration(seconds: 4));
      return PrintJob.fromJson(response['status']['print_stats']);
    } catch (error) {
      print('Failed to get print job status: $error');
      rethrow;
    }
  }

  Future<void> newPrinter() async {
    print('fetching initial printer status...');
    try {
      final results = await Future.wait([
        getPrinterState(),
        getExtruderStatus(),
        getHeaterBedStatus(),
        getToolheadStatus(),
      ]);
      final state = results[0] as PrinterState;
      final extruder = results[1] as Heater;
      final heaterBed = results[2] as Heater;
      final toolhead = results[3] as Toolhead;

      printer = Printer(
        state: state,
        extruder: extruder,
        heaterBed: heaterBed,
        toolhead: toolhead,
        fans: [],
      );
      notifyListeners();
    } catch (error) {
      print('Failed to initialize printer: $error');
    }
  }

  Future<void> subscribeHeaters() async {
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

        _updateHeatersFromStatus(status);
      });
      final response = await _rpc!
          .sendRequest('printer.objects.subscribe', {
            'objects': {
              'extruder': ['temperature', 'target', 'power'],
              'heater_bed': ['temperature', 'target', 'power'],
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
      printer?.extruder = Heater.fromJson(extruderJson);
      printer?.heaterBed = Heater.fromJson(heaterBedJson);
      notifyListeners();
    } catch (error) {
      print('Failed to get extruder status: $error');
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

  void emergencyStop() {
    if (_rpc == null || !_isConnected) {
      print('Not connected to Moonraker');
      return;
    }

    _rpc!.sendRequest('printer.emergency_stop').catchError((error) {
      print('Failed to send emergency stop: $error');
    });
  }
}
