import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_eliza/chat_screen.dart';

import 'package:http/http.dart' as http;

class ActiveAgent extends StatefulWidget {
  final String? walletAddress;
  const ActiveAgent({super.key, this.walletAddress});

  @override
  State<ActiveAgent> createState() => _ActiveAgentState();
}

class _ActiveAgentState extends State<ActiveAgent>
    with SingleTickerProviderStateMixin {
  List<dynamic> agents = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Fetch agents on screen load //
    fetchAgents();
  }

  Future<void> fetchAgents() async {
    final url = Uri.parse('http://10.0.2.2:3000/agents');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Parse JSON response //
        final Map<String, dynamic> decodedResponse = jsonDecode(response.body);
        if (decodedResponse.containsKey('agents')) {
          setState(() {
            agents = decodedResponse['agents'];
            isLoading = false;
          });
        } else {
          print('Key "agents" not found in response');
        }
      } else {
        print('Failed to load agents: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching agents: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Color(0xfff8f8f8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xfff8f8f8),
        title: Text(
          "Agents",
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              widget.walletAddress != null
                  ? '${widget.walletAddress!.substring(0, 4)}...${widget.walletAddress!.substring(widget.walletAddress!.length - 4)}'
                  : "Wallet Not Connected",
              style: TextStyle(fontSize: 12),
            ),
          )
        ],
      ),
      body: ListView.builder(
        itemCount: agents.length,
        itemBuilder: (context, index) {
          final agent = agents[index];
          return Container(
            height: screenHeight / 2,
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
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      agent["name"] ?? "Unknown Agent",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 20),
                  height: 200,
                  width: 300,
                  decoration: BoxDecoration(
                      color: Color(0xfff27272a),
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                  child: Center(
                    child: Text(
                      agent["name"],
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 38, top: 20),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      ChatScreen(agent: agent)));
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
                            )),
                      ),
                    ],
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
