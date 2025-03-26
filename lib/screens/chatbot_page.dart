// ignore_for_file: deprecated_member_use, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  _ChatbotPageState createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> messages = [];

  late WebSocketChannel _channel;

  @override
  void initState() {
    super.initState();
    _channel = WebSocketChannel.connect(
      Uri.parse('wss://fortunix.onrender.com/ws/chat'),
    );

    _channel.stream.listen((data) {
      final decoded = jsonDecode(data);
      final response = decoded["response"] ?? decoded["error"] ?? "No response received.";
      setState(() {
        messages.add({"bot": response});
      });
    });
  }

  void _sendMessage() {
    if (_controller.text.isEmpty) return;

    final userMessage = _controller.text;
    setState(() {
      messages.add({"user": userMessage});
      _controller.clear();
    });

    final payload = jsonEncode({"query": userMessage});
    _channel.sink.add(payload);
  }

  @override
  void dispose() {
    _channel.sink.close(status.goingAway);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0B0F1F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Financial Chatbot',
          style: TextStyle(
            fontFamily: GoogleFonts.orbitron().fontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.blueAccent.shade100,
            letterSpacing: 1.5,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.blueAccent.shade100),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg.containsKey("user");

                return Align(
                  alignment:
                  isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    margin: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient:
                      isUser
                          ? LinearGradient(
                        colors: [
                          Colors.blueAccent.withOpacity(0.2),
                          Colors.blueGrey.withOpacity(0.3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                          : LinearGradient(
                        colors: [
                          Colors.grey.shade900,
                          Colors.grey.shade800,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                        isUser
                            ? Colors.blueAccent.shade100.withOpacity(0.4)
                            : Colors.white12,
                      ),
                    ),
                      child: isUser
                          ? Text(
                        msg.values.first,
                        style: TextStyle(
                          color: Colors.blueAccent.shade100,
                          fontSize: 16,
                        ),
                      )
                          : MarkdownBody(
                        data: msg.values.first,
                        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                          p: TextStyle(color: Colors.white70, fontSize: 16),
                          strong: const TextStyle(fontWeight: FontWeight.bold),
                          h1: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                          h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                          h3: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                          listBullet: const TextStyle(color: Colors.white70),
                        ),
                      ),
                  ),
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFF1B1F2B),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurpleAccent.withOpacity(0.15),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _controller,
                style: TextStyle(color: Colors.white),
                cursorColor: Colors.deepPurpleAccent,
                decoration: InputDecoration(
                  hintText: 'Ask something about finance...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurpleAccent.shade200,
                    Colors.indigoAccent.shade100,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurpleAccent.withOpacity(0.3),
                    blurRadius: 12,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(Icons.send, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
