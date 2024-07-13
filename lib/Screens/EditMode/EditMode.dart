import 'package:flutter/material.dart';
import 'package:test_drive/Widgets/AddBoard_Widget.dart';
import 'package:test_drive/Widgets/BoardsList_Widget.dart';  

class EditMode extends StatefulWidget {
  final String userID;
  const EditMode({Key? key, required this.userID}) : super(key: key);

  @override
  State<EditMode> createState() => _EditModeState();
}

class _EditModeState extends State<EditMode> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Mode'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade600),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: BoardsListWidget(
                  userID: widget.userID,
                  refreshParent: () {
                    setState(() {});
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.bottomRight,
              child: AddBoardWidget(
                userID: widget.userID,
                onBoardAdded: () {
                  setState(() {});
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
