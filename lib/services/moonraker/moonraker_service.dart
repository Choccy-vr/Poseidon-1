import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:poseidon_1/services/moonraker/types/printer.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class MoonrakerService {
  Printer? printer;

  static Future<void> testPrinter({
    required String ip,
    required int port,
  }) async {
    final Uri wsURI = Uri.parse('ws://$ip:$port/websocket');
    final channel = WebSocketChannel.connect(wsURI);
    final rpc = Peer(channel.cast<String>());

    rpc.listen();

    final info = await rpc.sendRequest('printer.info');
    print(info);
  }
}
