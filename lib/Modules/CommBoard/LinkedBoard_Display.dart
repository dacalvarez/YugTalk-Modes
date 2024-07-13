import 'package:flutter/material.dart';
import 'package:test_drive/Modules/CommBoard/CommBoard_Mod.dart';
import 'package:test_drive/Widgets/ExploreToggle_Widget.dart';
import 'package:test_drive/Widgets/LangToggle_Widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LinkedBoardDisplay extends StatelessWidget {
  final String boardID;
  final VoidCallback onBack;
  final bool isEditMode;

  const LinkedBoardDisplay({
    Key? key,
    required this.boardID,
    required this.onBack,
    required this.isEditMode,
  }) : super(key: key);

  Future<String> getBoardName() async {
    DocumentSnapshot boardSnapshot = await FirebaseFirestore.instance.collection('board').doc(boardID).get();
    if (boardSnapshot.exists) {
      var boardData = boardSnapshot.data() as Map<String, dynamic>;
      return boardData['name'] ?? 'Linked Board';
    }
    return 'Linked Board';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getBoardName(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Loading...'),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(snapshot.data ?? 'Linked Board'),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack,
            ),
            actions: [
              ExploreToggle_Widget(isEditMode: isEditMode),
              const Padding(padding: EdgeInsets.only(left: 10)),
              LangToggle_Widget(isEditMode: isEditMode),
              const Padding(padding: EdgeInsets.only(left: 10)),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: CommBoard_Mod(
              boardID: boardID,
              isEditMode: isEditMode,
            ),
          ),
        );
      },
    );
  }
}
