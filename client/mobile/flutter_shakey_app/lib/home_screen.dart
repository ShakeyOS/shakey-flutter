import 'package:flutter/material.dart';
import 'package:flutter_shakey_app/agents.dart';
import 'package:flutter_shakey_app/agixt_agents.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Shakey"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AtiveAgent(),
                      ));
                },
                child: Text('Chat With shakey')),
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AgentScreen(),
                      ));
                },
                child: Text('Chat With Agixt')),
          ],
        ),
      ),
    );
  }
}
