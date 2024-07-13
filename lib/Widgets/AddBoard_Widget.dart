import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class AddBoardWidget extends StatefulWidget {
  final String userID;
  final Function() onBoardAdded;

  const AddBoardWidget({
    Key? key,
    required this.userID,
    required this.onBoardAdded,
  }) : super(key: key);

  @override
  _AddBoardWidgetState createState() => _AddBoardWidgetState();
}

class _AddBoardWidgetState extends State<AddBoardWidget> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _customRowsController = TextEditingController();
  final TextEditingController _customColumnsController = TextEditingController();
  String? _selectedDimension;
  bool _isCustomDimension = false;

  final List<String> _commonDimensions = [
    '2x2', '3x3', '4x4', '5x5', '6x6', '7x7', '8x8', '8x10', '10x10', '4x6'
  ];

  Future<int> _getNextDocumentID(BuildContext context) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('board').get();
      List<int> ids = querySnapshot.docs.map((doc) => int.parse(doc.id)).toList();
      if (ids.isEmpty) {
        return 1;
      } else {
        ids.sort();
        return ids.last + 1;
      }
    } catch (e) {
      print('Error fetching next document ID: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch next document ID: $e')),
      );
      return -1; // Return an invalid ID or handle appropriately
    }
  }

  Future<void> _addBoard(BuildContext parentContext, String name, String category, int rows, int columns) async {
    try {
      int newID = await _getNextDocumentID(parentContext);
      if (newID == -1) return; // Exit if fetching document ID failed

      DocumentReference boardRef = FirebaseFirestore.instance.collection('board').doc(newID.toString());

      await boardRef.set({
        'name': name,
        'ownerID': widget.userID,
        'category': category,
        'isMain': false,
        'rows': rows,
        'columns': columns,
      });

      // Creating a placeholder document in the 'words' subcollection
      await boardRef.collection('words').doc('placeholder').set({'initialized': true});

      widget.onBoardAdded();
    } catch (e) {
      print('Error adding board: $e');
      ScaffoldMessenger.of(parentContext).showSnackBar(
        SnackBar(content: Text('Failed to add board: $e')),
      );
    }
  }

  Future<void> _deleteBoard(String boardID) async {
    try {
      await FirebaseFirestore.instance.collection('board').doc(boardID).delete();
    } catch (e) {
      print('Error deleting board: $e');
    }
  }

  Future<void> _showAddBoardDialog(BuildContext parentContext) async {
    _nameController.clear();
    _categoryController.clear();
    _customRowsController.clear();
    _customColumnsController.clear();
    setState(() {
      _selectedDimension = null;
      _isCustomDimension = false;
    });

    showDialog(
      context: parentContext,
      barrierDismissible: false, // Prevent pop-up from closing when pressing outside
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Add New Board',
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
                      labelText: 'Category (Optional)',
                    ),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Board Dimensions',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedDimension,
                          isExpanded: true,
                          hint: const Text('Select Dimension'),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedDimension = newValue;
                              _isCustomDimension = _selectedDimension == 'Custom';
                              if (!_isCustomDimension && _selectedDimension != null) {
                                List<String> dims = _selectedDimension!.split('x');
                                _customRowsController.text = dims[0];
                                _customColumnsController.text = dims[1];
                              } else {
                                _customRowsController.clear();
                                _customColumnsController.clear();
                              }
                            });
                          },
                          items: _commonDimensions.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList()
                            ..add(const DropdownMenuItem<String>(
                              value: 'Custom',
                              child: Text('Custom'),
                            )),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customRowsController,
                          decoration: const InputDecoration(
                            labelText: 'Rows',
                          ),
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 18),
                          enabled: _isCustomDimension,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _customColumnsController,
                          decoration: const InputDecoration(
                            labelText: 'Columns',
                          ),
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 18),
                          enabled: _isCustomDimension,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
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
                    'Add',
                    style: TextStyle(fontSize: 18),
                  ),
                  onPressed: () {
                    if (_nameController.text.isNotEmpty &&
                        (_selectedDimension != null) &&
                        (_selectedDimension != 'Custom' || (_customRowsController.text.isNotEmpty && _customColumnsController.text.isNotEmpty))) {
                      int rows, columns;
                      if (_isCustomDimension) {
                        rows = int.tryParse(_customRowsController.text) ?? 4;
                        columns = int.tryParse(_customColumnsController.text) ?? 4;
                      } else if (_selectedDimension != null) {
                        List<String> dims = _selectedDimension!.split('x');
                        rows = int.parse(dims[0]);
                        columns = int.parse(dims[1]);
                      } else {
                        rows = 4;
                        columns = 4;
                      }
                      Navigator.of(context).pop();
                      _addBoard(parentContext, _nameController.text, _categoryController.text, rows, columns);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Board Name and Dimensions are required')),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        await _showAddBoardDialog(context);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        minimumSize: const Size(100, 50),
      ),
      child: const Text(
        'Add Board',
        style: TextStyle(color: Colors.black, fontSize: 20),
      ),
    );
  }
}
