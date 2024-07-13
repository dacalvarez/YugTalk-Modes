import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';

class LangToggle_Widget extends StatefulWidget {
  final bool isEditMode;  // Flag to determine the mode

  const LangToggle_Widget({Key? key, required this.isEditMode}) : super(key: key);

  @override
  _LangToggle_WidgetState createState() => _LangToggle_WidgetState();
}

class _LangToggle_WidgetState extends State<LangToggle_Widget> {
  final String _temporaryPassword = '1234';  // Temporary password
  bool _isEnglishSelected = true;

  @override
  Widget build(BuildContext context) {
    return FlutterSwitch(
      width: 100.0,
      height: 40.0,
      valueFontSize: 18.0,
      toggleSize: 45.0,
      value: _isEnglishSelected,
      borderRadius: 20.0,
      padding: 8.0,
      showOnOff: true,
      activeText: "Eng",
      inactiveText: "Tag",
      activeTextColor: Colors.black,
      inactiveTextColor: Colors.black,
      activeColor: Colors.amber,
      inactiveColor: Colors.amber,
      onToggle: (val) {
        if (widget.isEditMode) {
          _toggleLanguage();  // Direct toggle without password in edit mode
        } else {
          _showPasswordDialog(context, val);  // Prompt for password in me mode
        }
      },
    );
  }

  void _toggleLanguage() {
    setState(() {
      _isEnglishSelected = !_isEnglishSelected;
    });
  }

  void _showPasswordDialog(BuildContext context, bool val) {
    if (_isEnglishSelected != val) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          TextEditingController passwordController = TextEditingController();
          return AlertDialog(
            title: const Text('Switching Language?'),
            content: TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(hintText: 'Enter Password'),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();  // Allow users to cancel the action
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (passwordController.text == _temporaryPassword) {
                    Navigator.of(context).pop();  // Close the dialog
                    _toggleLanguage();  // Toggle the language setting
                  } else {
                    // Consider how to handle the wrong password case
                    // E.g., display a message or clear the text field
                    print('Wrong password');  // Provide user feedback
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          );
        },
      );
    } else {
      _toggleLanguage();
    }
  }
}
