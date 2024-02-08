import 'dart:async';
import 'dart:io';

import 'package:campus_recruitment/screens/admin/registerdcompanies.dart';
import 'package:campus_recruitment/screens/admin/registerdusers.dart';
import 'package:campus_recruitment/screens/student/start.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({Key? key}) : super(key: key);

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0;

  final StreamController<List<Map<String, dynamic>>> _eventsStreamController =
      StreamController<List<Map<String, dynamic>>>();

  @override
  void initState() {
    super.initState();
    _initializeEventsStream();
  }

  @override
  void dispose() {
    _eventsStreamController.close();
    super.dispose();
  }

  void _initializeEventsStream() {
    FirebaseFirestore.instance.collection('events').snapshots().listen(
      (QuerySnapshot<Map<String, dynamic>> snapshot) {
        List<Map<String, dynamic>> events = snapshot.docs
            .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> doc) => doc.data())
            .toList();
            

        _eventsStreamController.add(events);
        
      },
      onError: (error) {
        print('Error retrieving events: $error');
      },
    );
  }

  Future<void> _showAddEventDialog(BuildContext context) async {
    String eventName = '';
    DateTime eventDate = DateTime.now();
    TimeOfDay eventTime = TimeOfDay.now();
    String eventLocation = '';
    XFile? pickedImage;

    final picker = ImagePicker();

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: const Text('Add Event'),
            content: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  TextField(
                    decoration: const InputDecoration(labelText: 'Event Name'),
                    onChanged: (value) {
                      eventName = value;
                    },
                  ),
                  Row(
                    children: <Widget>[
                      Text(
                          'Event Date: ${DateFormat('dd-MM-yyyy').format(eventDate)}'),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: eventDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2101),
                          );
                          if (pickedDate != null && pickedDate != eventDate) {
                            setState(() {
                              eventDate = pickedDate;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Text('Event Time: ${eventTime.format(context)}'),
                      IconButton(
                        icon: const Icon(Icons.access_time),
                        onPressed: () async {
                          TimeOfDay? pickedTime = await showTimePicker(
                            context: context,
                            initialTime: eventTime,
                          );
                          if (pickedTime != null && pickedTime != eventTime) {
                            setState(() {
                              eventTime = pickedTime;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  TextField(
                    decoration:
                        const InputDecoration(labelText: 'Event Location'),
                    onChanged: (value) {
                      eventLocation = value;
                    },
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Add'),
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('events').add({
                    'eventName': eventName,
                    'eventDate': eventDate.toIso8601String().split('T')[0],
                    'eventTime': eventTime.format(context),
                    'eventLocation': eventLocation,
                    // 'eventImageURL': downloadURL,
                  });

                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Campus-Recruitment-Admin"),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 33, 75, 243),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const UserAccountsDrawerHeader(
              currentAccountPicture: Icon(
                Icons.person,
                size: 48.0,
                color: Colors.white,
              ),
              accountName: Text("Welcome"),
              accountEmail: Text("admin@gmail.com"),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Registered Companies"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisteredCompanies(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Registered Students"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisteredUsers(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StartPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: SizedBox(
        child: Row(
          children: [
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _eventsStreamController.stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  List<Map<String, dynamic>> events = snapshot.data!;

                  return events.isEmpty
                      ? const Center(
                          child: Text('No Events Found'),
                        )
                      : ListView.builder(
                          itemBuilder: (context, index) {
                            Map<String, dynamic> event = events[index];

                            return Card(
                              child: ListTile(
                                trailing: IconButton(
                                    onPressed: () {},
                                    icon: const Icon(Icons.close)),
                                leading: Container(
                                  width: 90,
                                  height: 90,
                                  decoration: const BoxDecoration(
                                    image: DecorationImage(
                                      image: AssetImage('assets/events.jpg'),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Event Name: ${event['eventName']}',
                                      style: const TextStyle(
                                          fontSize: 20, color: Colors.black),
                                    ),
                                    Text(
                                      'Event Date: ${event['eventDate']}',
                                      style: const TextStyle(
                                          fontSize: 16, color: Colors.black),
                                    ),
                                    Text(
                                      'Event Location: ${event['eventLocation']}',
                                      style: const TextStyle(
                                          fontSize: 16, color: Colors.black),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          itemCount: events.length,
                        );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: MouseRegion(
        onHover: (event) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Add Event'),
            ),
          );
        },
        child: FloatingActionButton(
          onPressed: () {
            _showAddEventDialog(context);
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
