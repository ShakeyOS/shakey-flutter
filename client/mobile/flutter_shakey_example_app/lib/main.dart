import 'package:flutter/material.dart';
import 'package:flutter_shakey_example_app/agents.dart';
import 'package:flutter_shakey_example_app/pump_fun.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      
      home: PumpPortal(),
      // AtiveAgent(),
      
    );
  }
}
