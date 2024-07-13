import 'package:flutter/material.dart';
import '/Widgets/Drawer_Widget.dart';
import 'MeMode.dart';
import 'package:test_drive/Screens/EditMode/EditMode.dart';

class Home_Screen extends StatefulWidget {
  const Home_Screen({Key? key}) : super(key: key);

  @override
  _Home_ScreenState createState() => _Home_ScreenState();
}

class _Home_ScreenState extends State<Home_Screen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to YugTalk!'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.deepPurple,
          ),
          tabs: const [
            Tab(text: 'Me Mode'),
            Tab(text: 'Edit Mode'),
            Tab(text: 'Activity Mode'),
          ],
        ),
      ),
      drawer: const DrawerWidget(),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          meModeContent(),
          passwordProtectedMode('Edit Mode'),
          passwordProtectedMode('Activity Mode'),
        ],
      ),
    );
  }

  Widget meModeContent() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Image.asset(
              'assets/images/me_mode.png',
              fit: BoxFit.contain,
              width: 200,
              height: 200,
            ),
          ),
          const Text(
            "Let's Communicate",
            style: TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => MeMode(userID: '2')));
            },
            child: const Text('Start now'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(120, 40),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget passwordProtectedMode(String modeName) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: Image.asset(
            'assets/images/edit_mode.png',
            fit: BoxFit.contain,
            width: 200,
            height: 200,
          ),
        ),
        Text(
          'Enter Password',
          style: const TextStyle(fontSize: 25),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 200, // Shortening the width of the password field
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    ),
                    obscureText: true, // for password input
                    initialValue: '12345',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 200, // Shortening the width of the enter button
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => EditMode(userID: 'user2')));                    },
                    child: const Text('Enter'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
