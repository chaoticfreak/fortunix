import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketService {
  final _channel = WebSocketChannel.connect(
    Uri.parse('ws://localhost:8000/ws/chat'), // Use local IP for real device
  );

  Stream<Map<String, dynamic>> get stream =>
      _channel.stream.map((data) => jsonDecode(data));

  void sendMessage(String query) {
    final data = jsonEncode({"query": query});
    _channel.sink.add(data);
  }

  void dispose() {
    _channel.sink.close(status.goingAway);
  }
}
