import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_drive/Modules/CommBoard/CommBoard_Mod.dart';
import 'package:test_drive/Screens/EditMode/CommBoard_Edit.dart';

class CommBoard_View extends StatefulWidget {
  final String boardID;
  final String userID;

  const CommBoard_View({Key? key, required this.boardID, required this.userID}) : super(key: key);

  @override
  _CommBoard_ViewState createState() => _CommBoard_ViewState();
}

class _CommBoard_ViewState extends State<CommBoard_View> {
  String boardName = 'Communication Board';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBoardName();
  }

  Future<void> _fetchBoardName() async {
    try {
      DocumentSnapshot boardDoc = await FirebaseFirestore.instance
          .collection('board')
          .doc(widget.boardID)
          .get();

      if (boardDoc.exists) {
        setState(() {
          boardName = boardDoc['name'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _refreshBoard() async {
    setState(() {
      isLoading = true;
    });
    await _fetchBoardName();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(boardName),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                bool? result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CommBoard_Edit(
                      boardID: widget.boardID,
                      userID: widget.userID,
                      refreshParent: _refreshBoard,
                    ),
                  ),
                );
                if (result == true) {
                  _refreshBoard();
                }
              },
            ),
            const Padding(padding: EdgeInsets.only(right: 10)),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : CommBoard_Mod(boardID: widget.boardID, isEditMode: true),
      ),
    );
  }
}
