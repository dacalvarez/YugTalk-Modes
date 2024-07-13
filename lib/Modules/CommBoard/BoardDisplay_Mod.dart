import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:test_drive/Modules/PopupForm/PopupForm_Mod.dart';
import 'dart:collection';

class BoardDisplay_Mod extends StatefulWidget {
  final String boardID;
  final Function(Map<String, String>) onSymbolSelected;
  final List<Map<String, String>> selectedSymbols;

  const BoardDisplay_Mod({
    Key? key,
    required this.boardID,
    required this.onSymbolSelected,
    required this.selectedSymbols,
  }) : super(key: key);

  @override
  _BoardDisplay_ModState createState() => _BoardDisplay_ModState();
}

class _BoardDisplay_ModState extends State<BoardDisplay_Mod> {
  int? rows;
  int? columns;
  bool isLoading = true;
  List<Map<String, dynamic>> symbols = [];
  final FlutterTts flutterTts = FlutterTts();
  final AudioPlayer audioPlayer = AudioPlayer();
  bool isSpeakingOrPlaying = false;
  Queue<String> speechQueue = Queue<String>();
  DateTime? lastTapTime;

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _fetchBoardDetails();
  }

  void _initializeTts() {
    flutterTts.setCompletionHandler(() async {
      if (speechQueue.isNotEmpty) {
        String nextPhrase = speechQueue.removeFirst();
        await flutterTts.speak(nextPhrase);
      } else {
        setState(() {
          isSpeakingOrPlaying = false;
        });
      }
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        isSpeakingOrPlaying = false;
      });
    });

    flutterTts.setSpeechRate(0.5);
    flutterTts.setPitch(1.2);
    flutterTts.setLanguage("en-US");
  }

  Future<void> _fetchBoardDetails() async {
    try {
      DocumentSnapshot boardSnapshot = await FirebaseFirestore.instance
          .collection('board')
          .doc(widget.boardID)
          .get();

      if (boardSnapshot.exists) {
        var boardData = boardSnapshot.data() as Map<String, dynamic>;
        setState(() {
          rows = boardData['rows'];
          columns = boardData['columns'];
        });
        _fetchSymbols();
      } else {
        setDefaultDimensions();
      }
    } catch (e) {
      setDefaultDimensions();
    }
  }

  void setDefaultDimensions() {
    setState(() {
      rows = 3;
      columns = 5;
      isLoading = false;
    });
    print('No or invalid dimensions, reverting to default: 5 columns, 3 rows.');
  }

  Future<void> _fetchSymbols() async {
    try {
      QuerySnapshot symbolsSnapshot = await FirebaseFirestore.instance
          .collection('board')
          .doc(widget.boardID)
          .collection('words')
          .orderBy(FieldPath.documentId)
          .get();

      setState(() {
        symbols = symbolsSnapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _incrementUsageCount(String boardID, String symbolID) async {
    try {
      DocumentReference symbolRef = FirebaseFirestore.instance
          .collection('board')
          .doc(boardID)
          .collection('words')
          .doc(symbolID);

      await symbolRef.update({
        'usageCount': FieldValue.increment(1),
      });
    } catch (e) {
      print("Error incrementing usage count: $e");
    }
  }

  void _playAudio(String url) async {
    try {
      setState(() {
        isSpeakingOrPlaying = true;
      });
      await audioPlayer.setUrl(url);
      await audioPlayer.play();
      audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          setState(() {
            isSpeakingOrPlaying = false;
          });
        }
      });
    } catch (e) {
      print("Error playing audio: $e");
      setState(() {
        isSpeakingOrPlaying = false;
      });
    }
  }

  void _speak(String text, String language) async {
    if (isSpeakingOrPlaying) {
      speechQueue.add(text);
    } else {
      setState(() {
        isSpeakingOrPlaying = true;
      });
      await flutterTts.setLanguage(language);
      await flutterTts.speak(text);
    }
  }

  void _playSymbolAudio(Map<String, dynamic> symbol) async {
    String? audioUrl = symbol['wordAudio'];
    String language = symbol['language'] ?? 'en-US';
    if (audioUrl != null && audioUrl.isNotEmpty) {
      _playAudio(audioUrl);
    } else {
      _speak(symbol['wordName'] ?? '', language);
    }
  }

  void _handleTap(Map<String, dynamic> symbol) async {
    DateTime now = DateTime.now();
    if (lastTapTime != null && now.difference(lastTapTime!).inMilliseconds < 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("You're tapping too fast! Slow down!"),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }
    lastTapTime = now;

    if (isSpeakingOrPlaying) return;

    if (symbol.containsKey('isLinked') && symbol['isLinked'] != null) {
      DocumentReference linkedBoardRef = symbol['isLinked'] as DocumentReference;
      DocumentSnapshot linkedBoardSnapshot = await linkedBoardRef.get();
      if (linkedBoardSnapshot.exists) {
        widget.onSymbolSelected({
          'isLinked': 'true',
          'linkedBoardID': linkedBoardRef.id,
        });
      }
    } else {
      if (widget.selectedSymbols.isEmpty || widget.selectedSymbols.last['id'] != symbol['id']) {
        widget.selectedSymbols.add({
          'symbol': symbol['symbol'] ?? '',
          'word': symbol['wordName'] ?? '',
          'wordAudio': symbol['wordAudio'] ?? '',
          'symbolImage': symbol['wordImage'] ?? '',
          'id': symbol['id'] ?? '',
          'language': symbol['language'] ?? 'en-US',
        });
        widget.onSymbolSelected({
          'symbol': symbol['symbol'] ?? '',
          'word': symbol['wordName'] ?? '',
          'wordAudio': symbol['wordAudio'] ?? '',
          'symbolImage': symbol['wordImage'] ?? '',
          'id': symbol['id'] ?? '',
          'language': symbol['language'] ?? 'en-US',
        });
      }
      _playSymbolAudio(symbol);
      await _incrementUsageCount(widget.boardID, symbol['id']);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (symbols.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No symbols found. To add symbols, go to edit mode.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
          ),
        ),
      );
    }

    final totalCells = rows! * columns!;
    final orderedSymbols = symbols.toList();

    while (orderedSymbols.length < totalCells) {
      orderedSymbols.add({'id': null});
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        double maxContainerWidth = constraints.maxWidth;
        double maxContainerHeight = constraints.maxHeight;
        double cellSize = ((maxContainerWidth - (columns! - 1) * 8.0 - 10) / columns!).clamp(0.0, (maxContainerHeight - (rows! - 1) * 8.0 - 10) / rows!).toDouble();

        double containerWidth = cellSize * columns! + (columns! - 1) * 8.0 + 10;
        double containerHeight = cellSize * rows! + (rows! - 1) * 8.0 + 10;

        return Center(
          child: Container(
            width: containerWidth,
            height: containerHeight,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns!,
                childAspectRatio: 1.0,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: totalCells,
              itemBuilder: (context, index) {
                final symbol = orderedSymbols[index];
                return GestureDetector(
                  onTap: () => _handleTap(symbol),
                  onLongPress: () async {
                    if (symbol['id'] != null) {
                      await _incrementUsageCount(widget.boardID, symbol['id']);
                      showPopupFormMod(context, widget.boardID, symbol['id']);
                    }
                  },
                  child: Container(
                    width: cellSize,
                    height: cellSize,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DragTarget<String>(
                      onAccept: (receivedID) {
                        // Handle symbol drag and drop if needed
                      },
                      builder: (context, candidateData, rejectedData) {
                        if (symbol['id'] == null) {
                          return Container(color: Colors.transparent);
                        } else {
                          return _buildSymbolContainer(symbol, cellSize);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSymbolContainer(Map<String, dynamic> data, double cellSize) {
    return SizedBox(
      width: cellSize,
      height: cellSize,
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool showImageOnly = constraints.maxHeight < 100;
          double imageSize = showImageOnly ? constraints.maxHeight * 0.7 : constraints.maxHeight * 0.5;
          double fontSize = showImageOnly ? 0 : 18;

          return Card(
            color: _getColorForCategory(data['wordCategory'] ?? ''),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 2,
            margin: const EdgeInsets.all(3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildImage(data['wordImage'], imageSize),
                if (!showImageOnly)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          data['wordName'] ?? '',
                          style: TextStyle(fontSize: fontSize),
                          textAlign: TextAlign.center,
                        ),
                        if (data.containsKey('isLinked') && data['isLinked'] != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: Icon(
                              Icons.grid_view_rounded,
                              size: fontSize,
                              color: Colors.black,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildImage(String? imageUrl, double maxHeight) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, color: Colors.red, size: maxHeight * 0.3),
          if (maxHeight > 100)
            const Text(
              'Error',
              style: TextStyle(color: Colors.red),
            ),
        ],
      );
    }

    bool isSvg = imageUrl.toLowerCase().endsWith('.svg');
    if (isSvg) {
      try {
        return SvgPicture.network(
          imageUrl,
          placeholderBuilder: (context) => const CircularProgressIndicator(),
          fit: BoxFit.contain,
          height: maxHeight,
        );
      } catch (e) {
        print("Error loading SVG: $e");
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: maxHeight * 0.3),
            if (maxHeight > 100)
              const Text(
                'Error',
                style: TextStyle(color: Colors.red),
              ),
          ],
        );
      }
    } else {
      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        height: maxHeight,
        errorBuilder: (context, error, stackTrace) {
          print("Error loading image: $error");
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: maxHeight * 0.3),
              if (maxHeight > 100)
                const Text(
                  'Error',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          );
        },
      );
    }
  }

  Color _getColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'nouns':
        return const Color(0xffffb33f);
      case 'pronouns':
        return const Color(0xffffe682);
      case 'verbs':
        return const Color(0xff9ee281);
      case 'adjectives':
        return const Color(0xff69c8ff);
      case 'prepositions':
      case 'social words':
        return const Color(0xffff8cd2);
      case 'questions':
        return const Color(0xffa77dff);
      case 'negation':
      case 'important words':
        return const Color(0xffff5150);
      case 'adverbs':
        return const Color(0xffc19b84);
      case 'conjunctions':
        return const Color(0xffffffff);
      default:
        return Colors.grey;
    }
  }
}

void showPopupFormMod(BuildContext context, String boardID, String symbolID) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return PopupFormMod(boardID: boardID, symbolID: symbolID);
    },
  );
}
