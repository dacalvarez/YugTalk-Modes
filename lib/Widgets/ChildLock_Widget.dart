import 'package:flutter/material.dart';
import 'package:test_drive/Screens/Home_Screen.dart';

class ChildLock_Widget extends StatefulWidget {
  const ChildLock_Widget({Key? key}) : super(key: key);

  @override
  _ChildLock_WidgetState createState() => _ChildLock_WidgetState();
}

class _ChildLock_WidgetState extends State<ChildLock_Widget> {
  int _tapCount = 0;
  final String _temporaryPassword = '1234'; // Temporary password

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _incrementTapCount,
      icon: const Icon(
        Icons.lock,
        size: 40,
      ),
    );
  }

  void _incrementTapCount() {
    setState(() {
      _tapCount++;
      if (_tapCount == 3) {
        _tapCount = 0; // Reset tap count after showing the dialog
        _showPasswordDialog(context);
      }
    });
  }

  void _showPasswordDialog(BuildContext context) {
    TextEditingController _passwordController = TextEditingController();
    bool _isPasswordWrong = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing the dialog by tapping outside it
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Leaving Me Mode?'),
              content: TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Enter Password',
                  errorText: _isPasswordWrong ? 'Wrong password, try again' : null,
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (_passwordController.text == _temporaryPassword) {
                      // Password is correct
                      Navigator.of(context).pop(); // Close the dialog
                      Navigator.pushReplacement( // Navigate to HomeScreen
                        context,
                        MaterialPageRoute(builder: (context) => const Home_Screen()),
                      );
                    } else {
                      setState(() {
                        _isPasswordWrong = true; // Show error message in dialog
                        _passwordController.clear(); // Clear the text field for retry
                      });
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
