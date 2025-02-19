import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stability_image_generation/stability_image_generation.dart';

class ImageScreen extends StatefulWidget {
  const ImageScreen({super.key});

  @override
  State<ImageScreen> createState() => _ImageScreenState();
}

class _ImageScreenState extends State<ImageScreen> {
  final TextEditingController _queryController = TextEditingController();
  final StabilityAI _ai = StabilityAI();
  final String apiKey = 'YOUR API KEY';
  final ImageAIStyle imageAIStyle = ImageAIStyle.studioPhoto;
  bool run = false;
  bool isGenerating = false;

  /// The [_generate function to generate image data.
  Future<Uint8List> _generate(String query) async {
    /// Call the generateImage method with the required parameters.
    Uint8List image = await _ai.generateImage(
      apiKey: apiKey,
      imageAIStyle: imageAIStyle,
      prompt: query,
    );
    return image;
  }

  @override
  void dispose() {
    /// Dispose the [_queryController].
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: Text("Image Generation"),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _queryController.clear();
                run = false;
              });
            },
            icon: Icon(Icons.clear),
          ),
        ],
      ),
      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  height: 500,
                  width: 500,
                  child: run
                      ? FutureBuilder<Uint8List>(
                          /// Call the [_generate] function to get the image data.
                          future: _generate(_queryController.text),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              /// While waiting for the image data, display a loading indicator.
                              return Center(
                                child: const CircularProgressIndicator(),
                              );
                            } else if (snapshot.hasError) {
                              /// If an error occurred while getting the image data, display an error message.
                              return Text('Error: ${snapshot.error}');
                            } else if (snapshot.hasData) {
                              //  TextField ko clear karne ke liye
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _queryController.clear();
                              });

                              /// If the image data is available, display the image using Image.memory().
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(snapshot.data!),
                              );
                            } else {
                              /// If no data is available, display a placeholder or an empty container.
                              return Container();
                            }
                          },
                        )
                      : const Center(
                          child: Text(
                            'Enter Text and Click the button to generate',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    flex: 15,
                    child: TextField(
                      cursorColor: Color(0xff909090),
                      style: TextStyle(color: Colors.white),
                      controller: _queryController,
                      maxLines: null,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Color(0xff1a1a1a),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                backgroundColor: Color(0xff0051c8),
                                radius: 20,
                                child: IconButton(
                                  onPressed: () {
                                    String query = _queryController.text;
                                    if (query.isNotEmpty) {
                                      FocusScope.of(context).unfocus();
                                      setState(() {
                                        run = true;
                                      });
                                    }
                                  },
                                  icon: Icon(
                                    Icons.send,
                                    color: Color(0xfff8f8f8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        hintText: "Type here...",
                        hintStyle: TextStyle(color: Color(0xff909090)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(40),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      ),
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
