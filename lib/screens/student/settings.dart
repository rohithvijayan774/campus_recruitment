import 'package:campus_recruitment/screens/student/first.dart';
import 'package:campus_recruitment/screens/student/start.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart'
    show FirebaseMessaging, RemoteMessage;
import 'package:flutter/material.dart';

class Settings extends StatefulWidget {
  const Settings({
    Key? key,
  }) : super(key: key);

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  String name = ''; // Variable to hold the student name
  bool isNotificationEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadStudentInfo();
    _setupFirebaseMessaging();
  }

  Future<void> _loadStudentInfo() async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        DocumentSnapshot usersSnapshot =
            await _firestore.collection('users').doc(user.uid).get();

        if (usersSnapshot.exists) {
          setState(() {
            name = usersSnapshot['name'];
          });

          print('Name: $name');
        } else {
          print('Document does not exist for user ${user.uid}');
        }
      } else {
        print('User is null');
      }
    } catch (e) {
      print("Error loading student information: $e");
    }
  }

  void _setupFirebaseMessaging() {
    _firebaseMessaging.requestPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print("Foreground Message Data: ${message.data}");
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      print("Opened App Message Data: ${message.data}");
    });
  }

  Future<void> _logout(context) async {
    try {
      await _auth.signOut();
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const StartPage(),
          ),
          (route) => false);
    } catch (e) {
      print("Error during logout: $e");
    }
  }

  void _toggleNotification(bool value) {
    setState(() {
      isNotificationEnabled = value;

      // Subscribe/unsubscribe from FCM topic based on the toggle
      if (isNotificationEnabled) {
        _firebaseMessaging.subscribeToTopic('jobs');
      } else {
        _firebaseMessaging.unsubscribeFromTopic('jobs');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 125.0, left: 10),
            child: Text(
              "Settings",
              style: TextStyle(
                color: Colors.black,
                fontSize: 35,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 50.0),
            child: Text(
              "Account",
              style: TextStyle(
                color: Colors.black45,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.grey,
                  width: 1.0,
                ),
                bottom: BorderSide(
                  color: Colors.grey,
                  width: 1.0,
                ),
              ),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundImage: AssetImage('assets/person.png'),
              ),
              title: Text(name),
              subtitle: Text(_auth.currentUser?.email ?? ''),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 60.0),
            child: Text(
              "General",
              style: TextStyle(
                color: Colors.black45,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Card(
            color: Colors.white,
            child: ListTile(
              title: const Text("Notification"),
              leading:
                  const Icon(Icons.notifications, color: Colors.blue, size: 30),
              trailing: Transform.scale(
                scale: 1,
                child: Switch(
                  value: isNotificationEnabled,
                  activeColor: Colors.blue,
                  inactiveTrackColor: Colors.white,
                  onChanged: _toggleNotification,
                ),
              ),
            ),
          ),
          Card(
            color: Colors.white,
            child: ListTile(
              title: const Text("Logout"),
              leading: const Icon(Icons.logout, color: Colors.blue, size: 30),
              trailing: GestureDetector(
                onTap: () {
                  _logout(context);
                },
                child: const Icon(Icons.arrow_right_alt,
                    color: Colors.blue), // Add color to the arrow button
              ),
              onTap: () {
                _logout(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
