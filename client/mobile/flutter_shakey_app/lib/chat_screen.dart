import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_shakey_app/image_screen.dart';
import 'package:flutter_shakey_app/language_service.dart';
import 'package:flutter_shakey_app/message.dart';
import 'package:flutter_shakey_app/voice_screen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_ml_kit/google_ml_kit.dart' as mlKit;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:typicons_flutter/typicons_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isVoiceInput = false;
  bool _isSpeaking = false;
  FlutterTts flutterTts = FlutterTts();
  String _selectedInputLanguageCode = 'en';
  String _selectedOutputLanguageCode = 'en';
  Map<String, String> _languagesMap = LanguageService.languagesMap;
  final mlKit.LanguageIdentifier _languageIdentifier =
      mlKit.GoogleMlKit.nlp.languageIdentifier();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  // Function to send a message to the agent and receive a response //
  Future<void> talkWithEliza(String userMsg) async {
    if (userMsg.isEmpty) return;

    setState(() {
      _message
          .add(Message(isUser: true, message: userMsg, date: DateTime.now()));
      _userInput.clear();
      _isLoading = true;
    });
    // API URL for the agent //
    final url = Uri.parse('http://10.0.2.2:3000/${widget.agent['id']}/message');

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
              responseData[0]['text'] ?? "No response from Shakey";

          setState(() {
            _message.add(Message(
              isUser: false,
              message: replyText,
              date: DateTime.now(),
            ));
          });
          if (_isVoiceInput) {
            await _speak(replyText);
          }
        } else {
          // Handle empty response case //
          setState(() {
            _message.add(Message(
              isUser: false,
              message: "Empty response from Shakey API.",
              date: DateTime.now(),
            ));
          });
        }
      } else {
        print('Error: ${response.statusCode}');
        setState(() {
          _message.add(Message(
            isUser: false,
            message: "Error communicating with Shakey API.",
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
        _isVoiceInput = false;
      });
    }
  }

  Future<void> _detectLanguage(String text) async {
    if (text.isEmpty) {
      return;
    }
    try {
      final String languageCode =
          await _languageIdentifier.identifyLanguage(text);

      if (LanguageService.languagesMap.containsKey(languageCode)) {
        setState(() {
          // Update the input language code with the detected language
          _selectedInputLanguageCode = languageCode;
          _selectedOutputLanguageCode = languageCode;
        });

        print("Detected language: $languageCode");
      } else {
        print("Language not supported");
      }
    } catch (e) {
      print("Language detection failed: $e");
    }
  }

  Future<void> _speak(String text) async {
    setState(() {
      _isSpeaking = true; // Disable mic button
    });
    await flutterTts.setLanguage(_selectedOutputLanguageCode);
    await flutterTts.setPitch(1.0);
    flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });

    await flutterTts.speak(text);
  }

  Future<void> _stopSpeaking() async {
    await flutterTts.stop();
    setState(() {
      _isSpeaking = false;
    });
  }

  void startListening() async {
    if (_isSpeaking) {
      await _stopSpeaking();
    }
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == "notListening") {
          setState(() => _isListening = false);
        }
      },
      onError: (errorNotification) {
        setState(() => _isListening = false);
      },
    );

    if (available) {
      setState(() {
        _isListening = true;
        _isVoiceInput = true;
      });

      // Setting a timer that will stop the speech after 5 seconds.
      Timer(const Duration(seconds: 5), () {
        if (_isListening) {
          stopListening();
        }
      });

      _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            _detectLanguage(result.recognizedWords);
            talkWithEliza(result.recognizedWords);
            stopListening(); // It will stop after the speech is recognized.
          }
        },
        pauseFor: const Duration(
            seconds: 2), // If nothing is spoken for 2 seconds, it will stop
        listenFor: const Duration(minutes: 1),
      );
    }
  }

  void stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isListening) {
          stopListening();
        }
        if (_isSpeaking) {
          await _stopSpeaking();
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Color(0xfff8f8f8),
        appBar: AppBar(
          title: Text(widget.agent['name'] ?? 'Chat'),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            VoiceScreen(agent: widget.agent)));
              },
              icon: Icon(Icons.smart_toy),
            ),
            IconButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => ImageScreen()));
                },
                icon: Icon(Icons.image))
          ],
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Shakey',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: SpinKitWave(
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                      )
                    ],
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
                        onTap: () {
                          if (_isSpeaking) {
                            _stopSpeaking();
                          }
                        },
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
                                  IconButton(
                                    icon: Icon(
                                      _isListening ? Icons.mic : Icons.mic_none,
                                      color: _isListening
                                          ? Colors.red
                                          : Colors.white,
                                    ),
                                    onPressed: () async {
                                      if (_isSpeaking) {
                                        await flutterTts
                                            .stop(); // Stop speaking
                                        setState(() => _isSpeaking = false);
                                        startListening(); // Start listening
                                      } else if (!_isListening) {
                                        startListening();
                                      }
                                    },
                                  ),
                                  CircleAvatar(
                                    backgroundColor: const Color(0xff0051c8),
                                    radius: 20,
                                    child: IconButton(
                                        onPressed: (_isLoading || _isSpeaking)
                                            ? null
                                            : () {
                                                setState(() =>
                                                    _isVoiceInput = false);
                                                talkWithEliza(_userInput.text);
                                                _userInput.clear();
                                              },
                                        icon: const Icon(
                                          Typicons.location_arrow_outline,
                                          color: Color(0xfff8f8f8),
                                        )),
                                  ),
                                ],
                              ),
                            ),
                            hintText: _isListening ? null : "Type here...",
                            hintStyle:
                                const TextStyle(color: Color(0xff909090)),
                            prefixIcon: _isListening
                                ? Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: SpinKitWave(
                                      size: 20,
                                      color: Colors.grey.shade400,
                                    ))
                                : null,
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
      ),
    );
  }
}
