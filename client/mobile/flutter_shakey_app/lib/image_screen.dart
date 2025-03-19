import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
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
  Uint8List? _generatedImage;

  /// The [_generate function to generate image data.
  Future<void> _generate(String query) async {
    /// Call the generateImage method with the required parameters.
    Uint8List image = await _ai.generateImage(
      apiKey: apiKey,
      imageAIStyle: imageAIStyle,
      prompt: query,
    );
    setState(() {
      _generatedImage = image;
    });
  }

  Future<void> _saveImageToGallery() async {
    if (_generatedImage != null) {
      final result = await ImageGallerySaverPlus.saveImage(_generatedImage!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Image saved to successful")),
      );
    }
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
                _generatedImage = null;
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
                      ? _generatedImage != null
                          ? Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.memory(_generatedImage!),
                                ),
                                SizedBox(height: 10),
                                ElevatedButton.icon(
                                  onPressed: _saveImageToGallery,
                                  icon: Icon(Icons.download),
                                  label: Text("Save Image"),
                                ),
                              ],
                            )
                          : Center(child: CircularProgressIndicator())
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
                                      _generate(query);
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
