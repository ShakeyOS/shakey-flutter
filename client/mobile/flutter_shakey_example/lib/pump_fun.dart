import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
// OR
import 'dart:math' hide log;
import 'package:flutter/material.dart';
import 'package:flutter_eliza/agents.dart';
import 'package:flutter_phantom/flutter_phantom.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import 'package:uni_links/uni_links.dart';

class PortalPump extends StatefulWidget {
  const PortalPump({super.key});

  @override
  State<PortalPump> createState() => _PortalPumpState();
}

class _PortalPumpState extends State<PortalPump>
    with SingleTickerProviderStateMixin {
  late WebSocketChannel _channel;
  List<Map<String, dynamic>> _messages = [];
  late ScrollController _scrollController;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  Map<int, bool> _highlightedMessages = {};
  Map<int, Timer> _highlightTimers = {};
  late StreamSubscription _sub;
  String logger = "";
  bool isLoading = false;
  String? walletAddress;

  // List of predefined colors for highlight //
  final List<Color> _highlightColors = [
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.red,
    Colors.purple,
    Colors.orange
  ];

  // Initialize the Phantom wallet connection //
  final FlutterPhantom phantom = FlutterPhantom(
    appUrl: "https://phantom.app",
    deepLink: "myapp://",
  );

  @override
  void initState() {
    // TODO: implement initState //
    super.initState();

    // Initialize ScrollController //
    _scrollController = ScrollController();

    // Connect to PumpPortal WebSocket //
    _channel =
        WebSocketChannel.connect(Uri.parse('wss://pumpportal.fun/api/data'));
    _handleIncomingLinks();

    _subscribeToEvents();

    // Initialize AnimationController for shake animation //
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: -10, end: 0).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.elasticIn,
      ),
    );

    _channel.stream.listen((message) async {
      try {
        final decodedMessage = jsonDecode(message);

        // Fetch additional data from URI //
        if (decodedMessage['uri'] != null) {
          final additionalData = await _fetchDataFromUri(decodedMessage['uri']);
          if (additionalData != null) {
            decodedMessage['additionalData'] = additionalData;
          }
        }

        setState(() {
          _messages.insert(0, decodedMessage);

          // // Highlight new message //
          _highlightedMessages[0] = true;

          _highlightTimers[0]?.cancel();

          _highlightTimers[0] = Timer(const Duration(milliseconds: 200), () {
            setState(() {
              _highlightedMessages[0] = false;
            });
          });
          // Start shake animation for the new message //
          _shakeController.reset();
          _shakeController.forward();
        });

        // Auto-scroll to top //
        _scrollToTop();
      } catch (e) {
        print("Error parsing message: $e");
      }
    });
  }

  // Subscribe to events using WebSocket //

  void _subscribeToEvents() {
    // Subscribing to new token creation events //
    _channel.sink.add(jsonEncode({
      "method": "subscribeNewToken",
    }));
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
    }
  }

  Future<Map<String, dynamic>?> _fetchDataFromUri(String uri) async {
    try {
      final response = await http.get(Uri.parse(uri));
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print("Error fetching data from URI: $e");
    }
    return null;
  }

  Future<void> _handleIncomingLinks() async {
    _sub = uriLinkStream.listen((Uri? link) {
      if (link != null) {
        log("Received Link: $link");
        final queryParams = link.queryParametersAll.entries.toList();

        if (queryParams.isNotEmpty) {
          switch (queryParams[0].value[0]) {
            case "onConnect":
              _handleConnectEvent(queryParams);
              break;
            case "onDisconnect":
              _handleDisconnectEvent();
              break;
            default:
              print("Unhandled event: ${queryParams[0].value[0]}");
          }
        }
      }
    }, onError: (err) {
      log("Error in deep link: $err");
    });
  }

  void _handleConnectEvent(List<MapEntry<String, List<String>>> queryParams) {
    Map dataConnect = phantom.onConnectToWallet(queryParams);
    inspect(dataConnect);

    setState(() {
      walletAddress = dataConnect['public_key'];
    });

    log("Wallet connected: $walletAddress");
  }

  void _handleDisconnectEvent() {
    try {
      // Retrieve disconnect data from Phantom SDK //
      String dataDisconnect = phantom.onDisconnectReceive();

      log("Wallet disconnected: $dataDisconnect");

      // Clear wallet address from UI //
      setState(() {
        walletAddress = null;
      });
    } catch (e) {
      log("Error handling disconnect event: $e");
    }
  }

  void connectToWallet() {
    try {
      setState(() {
        isLoading = true;
      });
      Uri uri =
          phantom.generateConnectUri(cluster: "devnet", redirect: "onConnect");
      launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
    } catch (e) {
      log("Error connecting to wallet: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void disconnectFromWallet() {
    try {
      setState(() {
        isLoading = true;
      });

      _handleDisconnectEvent();
    } catch (e) {
      log("Error disconnecting from wallet: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _shakeController.dispose();

    _channel.sink.close();
    _sub.cancel();
    super.dispose();
  }

  Color _getRandomHighlightColor() {
    final random = Random();
    return _highlightColors[random.nextInt(_highlightColors.length)];
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff1c1d27),
      appBar: AppBar(
        title: Text(walletAddress ?? "PumpPortal Event Stream"),
        actions: [
          IconButton(
            icon: Icon(Icons.wallet_rounded),
            onPressed: () {
              connectToWallet();

              print("connect");
            },
          ),
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              disconnectFromWallet();

              print("disconnect");
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isHighlighted =
                          _highlightedMessages[index] ?? false;
                      final additionalData = message['additionalData'] ?? {};
                      if (additionalData.isEmpty ||
                          (additionalData['name'] == null &&
                              additionalData['description'] == null)) {
                        return const SizedBox.shrink();
                      }
                      final highlightColor = isHighlighted
                          ? _getRandomHighlightColor()
                          : Colors.transparent;
                      return AnimatedBuilder(
                        animation: _shakeController,
                        builder: (context, child) {
                          final offset =
                              _shakeAnimation.value * (index == 0 ? 1 : 0);

                          return Transform.translate(
                            offset: Offset(offset, 2),
                            child: AnimatedContainer(
                              duration: const Duration(microseconds: 100),
                              curve: Curves.easeInOut,
                              child: Card(
                                color: highlightColor,
                                elevation: 4,
                                margin: const EdgeInsets.all(8.0),
                                child: ListTile(
                                  leading: additionalData['image'] != null
                                      ? Image.network(
                                          additionalData['image'],
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Icon(Icons.image);
                                          },
                                        )
                                      : const Icon(Icons.image),
                                  title: Text(
                                    additionalData['showName'] == true
                                        ? additionalData['name'] ?? 'No Name'
                                        : 'Anonymous',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xfff9ca3af)),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (additionalData['symbol'] != null)
                                        Text(
                                            'Symbol: ${additionalData['symbol']}',
                                            style: TextStyle(
                                                color: Color(0xfff9ca3af))),
                                      if (additionalData['description'] != null)
                                        Text(
                                            'Description: ${additionalData['description']}',
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                color: Color(0xfff9ca3af))),
                                      if (additionalData['createdOn'] != null)
                                        Text(
                                            'Market Cap (SOL): ${message['marketCapSol']?.toStringAsFixed(2) ?? 'N/A'}',
                                            style: TextStyle(
                                                color: Color(0xfff9ca3af))),
                                    ],
                                  ),
                                  isThreeLine: true,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ActiveAgent(
                                  walletAddress: walletAddress,
                                )));
                  },
                  backgroundColor: Colors.blue,
                  child: FaIcon(FontAwesomeIcons.robot),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
