import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_shakey_app/message.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:typicons_flutter/typicons_flutter.dart';

class ChatScreen extends StatefulWidget {
   // Agent data passed from the previous screen //
  final Map<String, dynamic> agent;
  const ChatScreen({super.key, required this.agent});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Controller for user input //
  TextEditingController _userInput = TextEditingController();
  // Stores chat messages //
  final List<Message> _message = [];
   // Indicates if the app is waiting for a response //
  bool _isLoading = false;

  // Function to send a message to the agent and receive a response //
  Future<void> talkWithEliza() async {
    final userMsg = _userInput.text;

    setState(() {
      _message
          .add(Message(isUser: true, message: userMsg, date: DateTime.now()));
      _userInput.clear();
      _isLoading = true;
    });
     // API URL for the agent //
    final url =
        Uri.parse('http://10.0.2.2:3000/${widget.agent['id']}/message');

    try {
      final response = await http.post(
        url,
        // JSON headers //
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'text': userMsg}),
      );
      print("Raw Response Body: ${response.body}");

      if (response.statusCode == 200) {
        // Parse the response as a List //
        final List<dynamic> responseData = json.decode(response.body);
        print("Parsed Response Data: $responseData");

        if (responseData.isNotEmpty) {
          final String replyText =
              responseData[0]['text'] ?? "No response from Eliza";

          setState(() {
            _message.add(Message(
              isUser: false,
              message: replyText,
              date: DateTime.now(),
            ));
          });
        } else {
          // Handle empty response case //
          setState(() {
            _message.add(Message(
              isUser: false,
              message: "Empty response from Eliza API.",
              date: DateTime.now(),
            ));
          });
        }
      } else {
        print('Error: ${response.statusCode}');
        setState(() {
          _message.add(Message(
            isUser: false,
            message: "Error communicating with Eliza API.",
            date: DateTime.now(),
          ));
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _message.add(Message(
          isUser: false,
          message: "An error occurred. Please try again later.",
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
                      date: DateFormat('HH:mm').format(message.date));
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
                            child: CircleAvatar(
                              backgroundColor: const Color(0xff0051c8),
                              radius: 20,
                              child: IconButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          talkWithEliza();
                                          
                                        },
                                  icon: const Icon(
                                    Typicons.location_arrow_outline,
                                    color: Color(0xfff8f8f8),
                                  )),
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