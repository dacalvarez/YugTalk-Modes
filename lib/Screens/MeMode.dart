import 'package:flutter/material.dart';
import 'package:test_drive/Widgets/ChildLock_Widget.dart';
import 'package:test_drive/Widgets/LangToggle_Widget.dart';
import 'package:test_drive/Widgets/ExploreToggle_Widget.dart';
import 'package:test_drive/Modules/CommBoard/CommBoard_Mod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MeMode extends StatefulWidget {
  final String userID; // Add userID as a required parameter

  const MeMode({super.key, required this.userID}); // Modify constructor to accept userID

  @override
  State<MeMode> createState() => _MeModeState();
}

class _MeModeState extends State<MeMode> {
  String? mainBoardID;
  List<String> userOwnedBoards = [];

  @override
  void initState() {
    super.initState();
    _fetchMainBoardID();
  }

  Future<void> _fetchMainBoardID() async {
    String userID = widget.userID; // Use the userID passed to the widget

    try {
      // Fetch boards owned by the user
      QuerySnapshot boardSnapshot = await FirebaseFirestore.instance
          .collection('board')
          .where('ownerID', isEqualTo: userID)
          .get();

      // Extract board IDs
      List<QueryDocumentSnapshot> ownedBoards = boardSnapshot.docs;
      List<String> ownedBoardIDs = ownedBoards.map((doc) => doc.id).toList();
      setState(() {
        userOwnedBoards = ownedBoardIDs;
      });

      // Fetch the main board
      QuerySnapshot mainBoardSnapshot = await FirebaseFirestore.instance
          .collection('board')
          .where('ownerID', isEqualTo: userID)
          .where('isMain', isEqualTo: true)
          .get();

      if (mainBoardSnapshot.docs.isNotEmpty) {
        setState(() {
          mainBoardID = mainBoardSnapshot.docs.first.id;
        });
      } else {
        _showSelectBoardDialog();
      }
    } catch (e) {
      // Handle errors appropriately
      print("Error fetching boards: $e");
    }
  }

  void _showSelectBoardDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Main Board'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: userOwnedBoards.map((boardID) {
            return ListTile(
              title: Text(boardID), // Replace with board name if available
              onTap: () {
                setState(() {
                  mainBoardID = boardID;
                });
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Me Mode'),
        centerTitle: true,
        leading: const ChildLock_Widget(),
        actions: const [
          ExploreToggle_Widget(isEditMode: false),
          Padding(padding: EdgeInsets.only(left: 10)),
          LangToggle_Widget(isEditMode: false),
          Padding(padding: EdgeInsets.only(left: 10)),
        ],
      ),
      body: mainBoardID != null
          ? CommBoard_Mod(boardID: mainBoardID!, isEditMode: false)
          : const Center(child: CircularProgressIndicator()), // Show loading indicator while fetching
    );
  }
}
