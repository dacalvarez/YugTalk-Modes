import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:collection';

class SymbolPlayer_Mod extends StatefulWidget {
  final List<Map<String, String>> selectedSymbols;

  const SymbolPlayer_Mod({Key? key, required this.selectedSymbols}) : super(key: key);

  @override
  _SymbolPlayer_ModState createState() => _SymbolPlayer_ModState();
}

class _SymbolPlayer_ModState extends State<SymbolPlayer_Mod> {
  final FlutterTts flutterTts = FlutterTts();
  bool isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

  void _initializeTts() {
    flutterTts.setStartHandler(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          isSpeaking = true;
        });
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        isSpeaking = false;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        isSpeaking = false;
      });
      _showErrorDialog(msg);
    });

    // Set TTS properties to make the voice less robotic
    flutterTts.setSpeechRate(0.5);
    flutterTts.setPitch(1.2);
    flutterTts.setLanguage("en-US");
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  void _playSymbols() async {
    if (widget.selectedSymbols.isEmpty) {
      _showSnackBar('Please select a symbol');
      return;
    }

    if (isSpeaking) return;

    String combinedText = '';
    for (var symbol in widget.selectedSymbols) {
      combinedText += '${symbol['word'] ?? ''} ';
    }

    await _speak(combinedText.trim(), 'en-US'); // Assuming all symbols are in the same language
  }

  Future<void> _speak(String text, String language) async {
    try {
      await flutterTts.setLanguage(language);
      await flutterTts.speak(text);
    } catch (e) {
      setState(() {
        isSpeaking = false;
      });
      _showErrorDialog(e.toString());
    }
  }

  void _clearQueue() {
    setState(() {
      widget.selectedSymbols.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isQueueEmpty = widget.selectedSymbols.isEmpty;

    return Material(
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: IconButton(
                icon: Icon(Icons.play_arrow, color: isQueueEmpty ? Colors.grey : Colors.black),
                iconSize: 32,
                onPressed: isQueueEmpty
                    ? null
                    : () {
                        _playSymbols();
                      },
              ),
            ),
            Expanded(
              child: Container(
                height: 60, // Reduced the height of the symbol player
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.selectedSymbols.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 60, // Made the container square and smaller
                      height: 60, // Made the container square and smaller
                      padding: const EdgeInsets.all(4.0),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: widget.selectedSymbols[index]['symbolImage'] != null
                          ? Image.network(
                              widget.selectedSymbols[index]['symbolImage']!,
                              fit: BoxFit.cover, // Ensure the image fits within the container
                            )
                          : Container(),
                    );
                  },
                ),
              ),
            ),
            SizedBox(
              width: 60,
              child: GestureDetector(
                onLongPress: isQueueEmpty
                    ? null
                    : () {
                        _clearQueue();
                      },
                child: IconButton(
                  icon: Icon(Icons.backspace, color: isQueueEmpty ? Colors.grey : Colors.black),
                  iconSize: 32,
                  onPressed: isQueueEmpty
                      ? null
                      : () {
                          setState(() {
                            widget.selectedSymbols.removeLast();
                          });
                        },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
