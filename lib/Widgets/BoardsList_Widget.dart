import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:test_drive/Screens/EditMode/CommBoard_View.dart';
import 'package:flutter/services.dart';


class BoardsListWidget extends StatefulWidget {
  final String userID;
  final Function() refreshParent;

  const BoardsListWidget({
    Key? key,
    required this.userID,
    required this.refreshParent,
  }) : super(key: key);

  @override
  _BoardsListWidgetState createState() => _BoardsListWidgetState();
}

class _BoardsListWidgetState extends State<BoardsListWidget> {
  int? _selectedBoardIndex;

  @override
  void initState() {
    super.initState();
    _ensureSingleMainBoard();
  }

  Future<void> _ensureSingleMainBoard() async {
    QuerySnapshot userBoards = await FirebaseFirestore.instance
        .collection('board')
        .where('ownerID', isEqualTo: widget.userID)
        .get();

    List<QueryDocumentSnapshot> mainBoards = userBoards.docs
        .where((doc) => (doc.data() as Map<String, dynamic>)['isMain'] == true)
        .toList();

    if (mainBoards.isEmpty && userBoards.docs.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('board')
          .doc(userBoards.docs.first.id)
          .update({'isMain': true});
    } else if (mainBoards.length > 1) {
      for (int i = 1; i < mainBoards.length; i++) {
        await FirebaseFirestore.instance
            .collection('board')
            .doc(mainBoards[i].id)
            .update({'isMain': false});
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchBoards() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('board')
          .get();

      List<Map<String, dynamic>> boards = querySnapshot.docs
          .where((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            bool isDefault = data['isDefault'] ?? false;
            List<dynamic> hiddenBy = data['hiddenBy'] ?? [];
            String ownerID = data['ownerID'] ?? '';

            if (hiddenBy.contains(widget.userID)) {
              return false;
            }

            if (isDefault || ownerID == widget.userID) {
              return true;
            }

            return false;
          })
          .map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'name': data['name'],
              'isDefault': data['isDefault'] ?? false,
              'isMain': data['isMain'] ?? false,
              'category': data['category'] ?? ''
            };
          })
          .toList();

      // Sort boards to place the main board at the top
      boards.sort((a, b) {
        if (a['isMain'] == true) {
          return -1;
        } else if (b['isMain'] == true) {
          return 1;
        } else {
          return 0;
        }
      });

      return boards;
    } catch (e) {
      print('Error fetching boards: $e');
      return [];
    }
  }

  Future<void> _setMainBoard(int index) async {
    final boards = await _fetchBoards();
    final board = boards[index];

    if (board['isDefault']) {
      await _duplicateAndHideDefaultBoard(index, board['name'], setAsMain: true);
    } else {
      final newMainBoardID = board['id'];

      final batch = FirebaseFirestore.instance.batch();

      // Set all other boards' isMain to false
      QuerySnapshot userBoards = await FirebaseFirestore.instance
          .collection('board')
          .where('ownerID', isEqualTo: widget.userID)
          .get();
      for (var doc in userBoards.docs) {
        batch.update(doc.reference, {'isMain': false});
      }

      // Set selected board's isMain to true
      batch.update(FirebaseFirestore.instance.collection('board').doc(newMainBoardID), {'isMain': true});

      await batch.commit();
      widget.refreshParent();
    }
  }

  void _confirmAction(int index, String action) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Confirm $action',
            style: const TextStyle(fontSize: 24),
          ),
          content: Text(
            'Are you sure you want to $action this board?',
            style: const TextStyle(fontSize: 18),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 18),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 18),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                if (action == 'delete') {
                  _deleteBoard(index);
                } else if (action == 'duplicate') {
                  _duplicateBoard(index);
                } else if (action == 'edit') {
                  _showEditDialog(index);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmSetMainBoard(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Set as Main Board',
            style: TextStyle(fontSize: 24),
          ),
          content: const Text(
            'Are you sure you want to set this board as the main board?',
            style: TextStyle(fontSize: 18),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 18),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text(
                'Set as Main',
                style: TextStyle(fontSize: 18),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _setMainBoard(index);
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(int index) async {
    TextEditingController _nameController = TextEditingController();
    TextEditingController _categoryController = TextEditingController();
    TextEditingController _rowsController = TextEditingController();
    TextEditingController _columnsController = TextEditingController();
    final boards = await _fetchBoards();
    final board = boards[index];
    final boardID = board['id'];
    final boardDoc = await FirebaseFirestore.instance.collection('board').doc(boardID).get();
    final boardData = boardDoc.data();

    if (board['isDefault']) {
      await _duplicateAndHideDefaultBoard(index, board['name'], edit: true);
    } else {
      if (boardData != null) {
        _nameController.text = boardData['name'];
        _categoryController.text = boardData['category'];
        _rowsController.text = boardData['rows'].toString();
        _columnsController.text = boardData['columns'].toString();
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'Edit Board',
              style: TextStyle(fontSize: 24),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Board Name',
                  ),
                  style: const TextStyle(fontSize: 18),
                ),
                TextField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                  ),
                  style: const TextStyle(fontSize: 18),
                ),
                TextField(
                  controller: _rowsController,
                  decoration: const InputDecoration(
                    labelText: 'Rows',
                  ),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 18),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
                TextField(
                  controller: _columnsController,
                  decoration: const InputDecoration(
                    labelText: 'Columns',
                  ),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 18),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 18),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text(
                  'Save',
                  style: TextStyle(fontSize: 18),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _editBoard(
                    index,
                    _nameController.text,
                    _categoryController.text,
                    int.parse(_rowsController.text),
                    int.parse(_columnsController.text),
                  );
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _editBoard(int index, String newName, String newCategory, int newRows, int newColumns) async {
    final boards = await _fetchBoards();
    final boardID = boards[index]['id'];
    await FirebaseFirestore.instance.collection('board').doc(boardID).update({
      'name': newName,
      'category': newCategory,
      'rows': newRows,
      'columns': newColumns,
    });
    widget.refreshParent();
  }

  void _duplicateBoard(int index) async {
    final boards = await _fetchBoards();
    final board = boards[index];

    if (board['isDefault']) {
      await _duplicateAndHideDefaultBoard(index, board['name']);
    } else {
      final boardID = board['id'];
      final boardDoc = await FirebaseFirestore.instance.collection('board').doc(boardID).get();
      final boardData = boardDoc.data();

      if (boardData != null) {
        int newID = await _getNextDocumentID();
        await FirebaseFirestore.instance.collection('board').doc(newID.toString()).set({
          'name': '${boardData['name']} (Copy)',
          'ownerID': widget.userID,
          'category': boardData['category'],
          'words': boardData['words'],
          'isMain': false,
        });
        widget.refreshParent();
      }
    }
  }

  void _deleteBoard(int index) async {
    final boards = await _fetchBoards();
    final board = boards[index];
    final boardID = board['id'];
    final boardDoc = await FirebaseFirestore.instance.collection('board').doc(boardID).get();
    final boardData = boardDoc.data();

    if (board['isDefault']) {
      await _duplicateAndHideDefaultBoard(index, board['name'], delete: true);
    } else {
      if (boardData != null) {
        await FirebaseFirestore.instance.collection('board').doc(boardID).delete();
      }
      widget.refreshParent();
    }
  }

  Future<void> _duplicateAndHideDefaultBoard(int index, String boardName,
      {bool setAsMain = false, bool edit = false, bool delete = false}) async {
      final boards = await _fetchBoards();
      final boardID = boards[index]['id'];
      final boardDoc = await FirebaseFirestore.instance.collection('board').doc(boardID).get();
      final boardData = boardDoc.data();

    if (boardData != null) {
      int newID = await _getNextDocumentID();
      await FirebaseFirestore.instance.collection('board').doc(newID.toString()).set({
        'name': boardName,
        'ownerID': widget.userID,
        'category': boardData['category'],
        'words': boardData['words'],
        'isMain': setAsMain,
      });

      await FirebaseFirestore.instance.collection('board').doc(boardID).update({
        'hiddenBy': FieldValue.arrayUnion([widget.userID])
      });

      widget.refreshParent();
      if (edit) {
        _showEditDialog(index);
      } else if (delete) {
        _deleteBoard(index);
      }
    }
  }

  Future<int> _getNextDocumentID() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('board').get();
    List<int> ids = querySnapshot.docs.map((doc) => int.parse(doc.id)).toList();
    if (ids.isEmpty) {
      return 1;
    } else {
      ids.sort();
      return ids.last + 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchBoards(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading data: ${snapshot.error}'));
        } else {
          final boards = snapshot.data ?? [];

          if (boards.isEmpty) {
            return const Center(child: Text('No boards found.'));
          }

          return SlidableAutoCloseBehavior(
            child: ListView.builder(
              itemCount: boards.length,
              itemBuilder: (context, index) {
                final board = boards[index];

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Slidable(
                      key: ValueKey(board['id']),
                      startActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        extentRatio: 0.25,
                        children: [
                          SlidableAction(
                            onPressed: (_) => _confirmAction(index, 'duplicate'),
                            borderRadius: BorderRadius.circular(12),
                            backgroundColor: const Color(0xFF21B7CA),
                            foregroundColor: Colors.white,
                            icon: Icons.copy,
                            label: 'Duplicate',
                          ),
                          SlidableAction(
                            onPressed: (_) => _confirmSetMainBoard(index),
                            borderRadius: BorderRadius.circular(12),
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            icon: Icons.star,
                            label: 'Set as Main',
                          ),
                        ],
                      ),
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        extentRatio: 0.25,
                        children: [
                          SlidableAction(
                            onPressed: (_) => _confirmAction(index, 'edit'),
                            borderRadius: BorderRadius.circular(12),
                            backgroundColor: const Color(0xFF2196F3),
                            foregroundColor: Colors.white,
                            icon: Icons.edit,
                            label: 'Edit',
                          ),
                          SlidableAction(
                            onPressed: (_) => _confirmAction(index, 'delete'),
                            borderRadius: BorderRadius.circular(12),
                            backgroundColor: const Color(0xFFFE4A49),
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            label: 'Delete',
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        leading: const Icon(Icons.dashboard),
                        title: Text(
                          board['name'],
                          style: const TextStyle(fontSize: 20),
                        ),
                        trailing: board['isMain']
                            ? const Icon(Icons.star, color: Colors.yellow)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedBoardIndex = index;
                          });
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CommBoard_View(
                                boardID: board['id'],
                                userID: widget.userID,
                              ),
                            ),
                          ).then((_) {
                            setState(() {
                              // Trigger a refresh when returning from CommBoard_View
                            });
                          });
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }
      },
    );
  }


}
