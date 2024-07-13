import 'package:flutter/material.dart';
import 'package:test_drive/Modules/CommBoard/SymbolPlayer_Mod.dart';
import 'package:test_drive/Modules/CommBoard/BoardDisplay_Mod.dart';
import 'package:test_drive/Modules/CommBoard/LinkedBoard_Display.dart';

class CommBoard_Mod extends StatefulWidget {
  final String boardID;
  final bool isEditMode;

  const CommBoard_Mod({
    Key? key,
    required this.boardID,
    required this.isEditMode,
  }) : super(key: key);

  @override
  _CommBoard_ModState createState() => _CommBoard_ModState();
}

class _CommBoard_ModState extends State<CommBoard_Mod> {
  List<Map<String, String>> selectedSymbols = [];
  late String currentBoardID;

  @override
  void initState() {
    super.initState();
    currentBoardID = widget.boardID;
  }

  void onSymbolSelected(Map<String, String> symbolData) {
    if (symbolData.containsKey('isLinked') && symbolData['isLinked'] == 'true') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LinkedBoardDisplay(
            boardID: symbolData['linkedBoardID']!,
            onBack: () {
              Navigator.pop(context);
            },
            isEditMode: widget.isEditMode,
          ),
        ),
      );
    } else {
      setState(() {
        if (!selectedSymbols.any((element) => element['symbol'] == symbolData['symbol'])) {
          selectedSymbols.add(symbolData);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          SymbolPlayer_Mod(selectedSymbols: selectedSymbols),
          const SizedBox(height: 20),
          Expanded(
            child: BoardDisplay_Mod(
              boardID: currentBoardID,
              onSymbolSelected: onSymbolSelected,
              selectedSymbols: selectedSymbols, // Pass the selectedSymbols here
            ),
          ),
        ],
      ),
    );
  }
}
