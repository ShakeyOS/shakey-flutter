import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
// OR
import 'dart:math' hide log;
import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';
import 'package:flutter_shakey_example_app/agents.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pinenacl/x25519.dart';
import 'package:bs58/bs58.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class PumpPortal extends StatefulWidget {
  const PumpPortal({super.key});

  @override
  State<PumpPortal> createState() => _PumpPortalState();
}

class _PumpPortalState extends State<PumpPortal>
    with SingleTickerProviderStateMixin {
  late WebSocketChannel _channel;
  List<Map<String, dynamic>> _messages = [];
  late ScrollController _scrollController; // Scroll Controller
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  Map<int, bool> _highlightedMessages = {}; // Track highlighted messages
  Map<int, Timer> _highlightTimers = {}; // Track timers for each message
  String logger = "";
  bool isLoading = false;
  late PrivateKey _dAppSecretKey;
  late PublicKey dAppPublicKey;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription? _linkSubscription;
  String? walletPublicKey;


  // List of predefined colors for highlight
  final List<Color> _highlightColors = [
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.red,
    Colors.purple,
    Colors.orange
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    // Initialize ScrollController
    _scrollController = ScrollController();
    // Connect to PumpPortal WebSocket
    _channel =
        WebSocketChannel.connect(Uri.parse('wss://pumpportal.fun/api/data'));

    _dAppSecretKey = PrivateKey.generate();
    dAppPublicKey = _dAppSecretKey.publicKey;
    _initDeepLinkListener();
    _subscribeToEvents();

    // Initialize AnimationController for shake animation
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

        // Fetch additional data from URI
        if (decodedMessage['uri'] != null) {
          final additionalData = await _fetchDataFromUri(decodedMessage['uri']);
          if (additionalData != null) {
            decodedMessage['additionalData'] = additionalData;
          }
        }

        setState(() {
          _messages.insert(0, decodedMessage);

          // // Highlight new message
          _highlightedMessages[0] = true;

          // // Remove highlight after 1 second
          _highlightTimers[0]?.cancel();

          _highlightTimers[0] = Timer(const Duration(milliseconds: 200), () {
            setState(() {
              _highlightedMessages[0] = false;
            });
          });
          // Start shake animation for the new message
          _shakeController.reset();
          _shakeController.forward();
        });

        // Auto-scroll to top
        _scrollToTop();
      } catch (e) {
        print("Error parsing message: $e");
      }
    });
  }

  String getEncodedPublicKey() {
    return base58.encode(dAppPublicKey.toUint8List());
  }

  Future<void> connectToPhantom() async {
    const String appUrl = 'https://phantom.app';
    const String redirectLink = 'myapp://connect';

    final Uri phantomUrl = Uri.parse('phantom://v1/connect').replace(
      queryParameters: {
        'dapp_encryption_public_key': getEncodedPublicKey(),
        'cluster': 'mainnet-beta',
        'app_url': appUrl,
        'redirect_link': redirectLink,
      },
    );

    print('Attempting to open Phantom Wallet with URL: $phantomUrl');

    await launchUrl(phantomUrl);
  }

  Future<void> _initDeepLinkListener() async {
    try {
      final Uri? initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }

      _linkSubscription = _appLinks.uriLinkStream.listen((Uri? link) {
        if (link != null) {
          _handleDeepLink(link);
        }
      });
    } catch (e) {
      print('Error receiving deep link: $e');
    }
  }

  void _handleDeepLink(Uri link) {
    print('Handling Deep Link: $link');
    Map<String, String> params = link.queryParameters;

    if (params.containsKey('phantom_encryption_public_key') &&
        params.containsKey('data')) {
      final encryptedData = params['data']!;

      // You can directly get the wallet address here without decryption
      setState(() {
        walletPublicKey = params['phantom_encryption_public_key'];
      });
      print('Wallet Address: $walletPublicKey');
    } else {
      print('No wallet address found.');
    }
  }

  void disconnectWallet() {
    setState(() {
      walletPublicKey = null;
    });
    print("Disconnected from Phantom Wallet");
  }

  void _subscribeToEvents() {
    // Subscribing to new token creation events
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

  Color _getRandomHighlightColor() {
    final random = Random();
    return _highlightColors[random.nextInt(_highlightColors.length)];
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff1c1d27),
      appBar: AppBar(
        title: Text(walletPublicKey ?? "PumpPortal Event Stream"),
        actions: [
          IconButton(
            icon: Icon(Icons.wallet_rounded),
            onPressed: connectToPhantom,
          ),
          IconButton(
              onPressed: walletPublicKey != null ? disconnectWallet : null,
              icon: Icon(Icons.exit_to_app))
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
                            builder: (context) => AtiveAgent(
                                  walletPublicKey: walletPublicKey,
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
