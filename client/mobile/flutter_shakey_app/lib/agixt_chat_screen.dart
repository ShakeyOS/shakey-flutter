import 'dart:async';
import 'dart:convert';

import 'package:agixtsdk/agixtsdk.dart';

import 'package:flutter/material.dart';
import 'package:flutter_shakey_app/agixt_service.dart';
import 'package:flutter_shakey_app/message.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class AgixtChatScreen extends StatefulWidget {
  // Agent data passed from the previous screen //
  final Map<String, dynamic> agent;
  const AgixtChatScreen({super.key, required this.agent});

  @override
  State<AgixtChatScreen> createState() => _AgixtChatScreenState();
}

class _AgixtChatScreenState extends State<AgixtChatScreen> {
  // Controller for user input //
  TextEditingController _userInput = TextEditingController();
  // Stores chat messages //
  final List<Message> _message = [];
  // Indicates if the app is waiting for a response //
  bool _isLoading = false;

  final AGiXTSDK agixtSDK = AGiXTService().agixtSDK;

  @override
  void initState() {
    super.initState();
  }

  // AGiXT se chat karne ka function
  Future<void> talkWithAgent(String userMsg) async {
    if (userMsg.isEmpty) return;

    setState(() {
      _message
          .add(Message(isUser: true, message: userMsg, date: DateTime.now()));
      _isLoading = true;
    });

    try {
      final chatResponse = await agixtSDK.chat(
        widget.agent['name'], // Agent Name
        userMsg, // User input
        'Test Conversation', // Conversation ID
      );

      setState(() {
        _message.add(Message(
          isUser: false,
          message: chatResponse, // API response
          date: DateTime.now(),
        ));
      });
    } catch (e) {
      setState(() {
        _message.add(Message(
          isUser: false,
          message: "Error communicating with agent.",
          date: DateTime.now(),
        ));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff8f8f8),
      appBar: AppBar(
        title: Text(widget.agent['name'] ?? 'Chat'),
        backgroundColor: Color(0xfff8f8f8),
      ),
      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _message.length,
                itemBuilder: (context, index) {
                  final message = _message[index];
                  return Messages(
                    isUser: message.isUser,
                    message: message.message,
                    date: DateFormat('HH:mm').format(message.date),
                  );
                },
              ),
            ),
            // Show typing indicator when loading //
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Typing...',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 15,
                    child: TextField(
                      cursorColor: const Color(0xff909090),
                      style: TextStyle(
                        color: Colors.white,
                      ),
                      controller: _userInput,
                      enabled: !_isLoading,
                      maxLines: null,
                      decoration: InputDecoration(
                          filled: true,
                          fillColor: Color(0xfff1a1a1a),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xff0051c8),
                                  radius: 20,
                                  child: IconButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () {
                                              talkWithAgent(_userInput.text);
                                              _userInput.clear();
                                            },
                                      icon: const Icon(
                                        Icons.send,
                                        // Typicons.location_arrow_outline,
                                        color: Color(0xfff8f8f8),
                                      )),
                                ),
                              ],
                            ),
                          ),
                          hintText: "Type here...",
                          hintStyle: const TextStyle(color: Color(0xff909090)),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 20)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
