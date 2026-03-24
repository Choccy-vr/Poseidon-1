import 'dart:async';
import 'dart:math';

import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:poseidon_1/services/moonraker/types/printer.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class MoonrakerService {
  Printer? printer;

  static int _retryCount = 0;
  static Timer? _reconnectTimer;
  static bool _isConnecting = false;

  static String? _lastKnownIP;
  static int? _lastKnownPort;

  static WebSocketChannel? _channel;
  static Peer? _rpc;

  static Future<void> connectPrinter({
    required String ip,
    required int port,
  }) async {
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
      _retryCount = 0;

      print('Connected to Moonraker at $ip:$port');

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
    } catch (error) {
      print('Connection failed: $error');
      _scheduleReconnect();
    } finally {
      _isConnecting = false;
    }
  }

  static void _scheduleReconnect() {
    if ((_reconnectTimer?.isActive ?? false) || _isConnecting) {
      return;
    }

    if (_lastKnownIP == null || _lastKnownPort == null) {
      return;
    }

    _retryCount++;

    final delay = Duration(seconds: min(30, 1 << (_retryCount - 1)));
    print('Reconnecting in ${delay.inSeconds}s...');

    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      unawaited(connectPrinter(ip: _lastKnownIP!, port: _lastKnownPort!));
    });
  }

  static void _handleDisconnect() {
    unawaited(
      _disposeConnection().whenComplete(() {
        _scheduleReconnect();
      }),
    );
  }

  static Future<void> _disposeConnection() async {
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

  static Future<void> testPrinterInfo() async {
    if (_rpc == null) {
      print('Not connected to Moonraker');
      return;
    }

    try {
      final result = await _rpc!.sendRequest('printer.info');
      print('Printer Info: $result');
    } catch (error) {
      print('Error calling printer.info: $error');
    }
  }
}
