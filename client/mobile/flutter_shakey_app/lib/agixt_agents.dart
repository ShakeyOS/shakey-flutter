import 'dart:convert';

import 'package:agixtsdk/agixtsdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_shakey_app/agixt_chat_screen.dart';
import 'package:flutter_shakey_app/agixt_service.dart';
import 'package:http/http.dart' as http;

class AgentScreen extends StatefulWidget {
  const AgentScreen({super.key});

  @override
  State<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen> {
  List<dynamic> agents = [];
  bool isLoading = true;
  final AGiXTSDK agixtSDK = AGiXTService().agixtSDK;

  @override
  void initState() {
    super.initState();
    // Fetch agents on screen load
    fetchAgents();
  }

  Future<void> fetchAgents() async {
    try {
      final agentsList = await agixtSDK.getAgents();
      print('Agent list here $agentsList');
      setState(() {
        agents = agentsList; // API se jo list aaye usko assign karein
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching agents: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff8f8f8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xfff8f8f8),
        title: const Text(
          "Agents",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Loading indicator
          : ListView.builder(
              itemCount: agents.length,
              itemBuilder: (context, index) {
                final agent = agents[index];
                return Container(
                  height: 400,
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Color(0xfff1d1d1d),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            'AGIXT',
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 20, left: 5),
                        height: 200,
                        width: 300,
                        decoration: const BoxDecoration(
                            color: Color(0xfff27272a),
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        child: Center(
                          child: Text(
                            'AGIXT',
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 10, top: 20),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      AgixtChatScreen(agent: agent)),
                            );
                          },
                          child: Container(
                            height: 50,
                            width: 300,
                            decoration: BoxDecoration(
                              color: Color(0xfff27272a),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                "Chat",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }
}
