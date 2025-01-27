import 'package:flutter/material.dart';
import 'package:flutter_eliza/agents.dart';
import 'package:flutter_eliza/chat_screen.dart';
import 'package:flutter_eliza/pump_fun.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      home: PortalPump(),
      // ActiveAgent(),
      // ChatScreen()
    );
  }
}
