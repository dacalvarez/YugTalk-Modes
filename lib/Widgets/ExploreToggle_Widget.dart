import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';

class ExploreToggle_Widget extends StatefulWidget {
  final bool isEditMode;  // Flag to determine if it's in edit mode

  const ExploreToggle_Widget({Key? key, required this.isEditMode}) : super(key: key);

  @override
  _ExploreToggle_WidgetState createState() => _ExploreToggle_WidgetState();
}

class _ExploreToggle_WidgetState extends State<ExploreToggle_Widget> {
  final String _temporaryPassword = '1234';
  bool _isSelected = true;

  @override
  Widget build(BuildContext context) {
    return FlutterSwitch(
      width: 100.0,
      height: 40.0,
      valueFontSize: 20.0,
      toggleSize: 45.0,
      value: _isSelected,
      borderRadius: 30.0,
      padding: 8.0,
      showOnOff: true,
      activeText: "🔎",
      inactiveText: "❌",
      activeTextColor: Colors.black,
      inactiveTextColor: Colors.black,
      activeColor: Colors.amber,
      inactiveColor: Colors.red,
      onToggle: (val) {
        if (widget.isEditMode) {
          // If in edit mode, toggle without asking for password
          _toggleExplore();
        } else {
          // If not in edit mode, prompt for password
          _showPasswordDialog(context, val);
        }
      },
    );
  }

  void _toggleExplore() {
    setState(() {
      _isSelected = !_isSelected;
    });
  }

  void _showPasswordDialog(BuildContext context, bool val) {
    if (_isSelected != val) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          TextEditingController passwordController = TextEditingController();
          return AlertDialog(
            title: const Text('Want To Explore?'),
            content: TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(hintText: 'Enter Password'),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  if (passwordController.text == _temporaryPassword) {
                    Navigator.of(context).pop(); // Close the dialog
                    _toggleExplore(); // Toggle the switch after successful password entry
                  } else {
                    // Optionally, handle wrong password case
                    Navigator.of(context).pop(); // Consider closing the dialog or prompting again
                    print('Wrong password'); // Or provide user feedback within the dialog
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          );
        },
      );
    } else {
      _toggleExplore(); // This else branch may be redundant based on your needs
    }
  }
}
