import 'dart:io';

import 'package:campus_recruitment/screens/student/Studentprofile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class StudentProfile2 extends StatefulWidget {
  const StudentProfile2({super.key});

  @override
  State<StudentProfile2> createState() => _StudentProfile2State();
}

class _StudentProfile2State extends State<StudentProfile2> {
  ImagePicker picker = ImagePicker();
  File? pickedImage;
  File? resumeFile;
  User? _user;
  String? _name;
  String? _lastName;
  String? _field;
  String? _email;
  String? _dob;
  String? _phoneNumber;
  String? _gender;
  String? _experience;
  String? _qualification;
  String? _skills;

  Future<void> _getUserDetails() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot<Map<String, dynamic>> snapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (snapshot.exists) {
          Map<String, dynamic>? data = snapshot.data();

          if (data != null) {
            _user = user;
            _name = data['name'] ?? '';
            _lastName = data['lastName'] ?? '';
            _email = data['email'] ?? '';
            _field = data['field'] ?? '';
            _dob = data['dob'] ?? '';
            _phoneNumber = data['phoneNumber'] ?? '';
            _gender = data['gender'] ?? '';
            _experience = data['experience'] ?? '';
            _qualification = data['qualification'] ?? '';
            _skills = data['skill'] ?? '';
          } else {
            print('User data not found in the snapshot');
          }
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _updateUserDetails() async {
    try {
      if (pickedImage != null) {
        // Upload profile picture to Firebase Storage
        String profilePicUrl = await _uploadFile(pickedImage!, 'profile_pics');
        _updateUserProfilePic(profilePicUrl);
      }

      if (resumeFile != null) {
        // Upload resume to Firebase Storage
        String resumeUrl = await _uploadFile(resumeFile!, 'resumes');
        _updateUserResume(resumeUrl);
      }

      // Update other user details in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .update({
        'name': _name,
        'lastName': _lastName,
        'email': _email,
        'field': _field,
        'dob': _dob,
        'phoneNumber': _phoneNumber,
        'gender': _gender,
        'experience': _experience,
        'qualification': _qualification,
        'skill': _skills,
      });
    } catch (e) {
      print('Error updating user details: $e');
    }
  }

  Future<String> _uploadFile(File file, String storageFolder) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageReference =
          FirebaseStorage.instance.ref().child('$storageFolder/$fileName');
      UploadTask uploadTask = storageReference.putFile(file);
      await uploadTask.whenComplete(() => null);

      String downloadUrl = await storageReference.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      throw Exception('File upload failed');
    }
  }

  void _updateUserProfilePic(String profilePicUrl) {
    FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({
      'profilePicUrl': profilePicUrl,
    });
  }

  void _updateUserResume(String resumeUrl) {
    FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({
      'resumeUrl': resumeUrl,
    });
  }

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        pickedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> pickResume() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path ?? "");
      setState(() {
        resumeFile = file;
      });
    }
  }

  OutlineInputBorder _customBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: const BorderSide(width: 0.5, color: Colors.black),
    );
  }

  @override
  void initState() {
    super.initState();
    _getUserDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
          future: _getUserDetails(),
          builder: (context, snapshot) {
            return snapshot.connectionState == ConnectionState.waiting
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          height: 300,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: 16,
                                right: 16,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const StudentProfile(),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.white,
                                  ),
                                  child: const Text(
                                    "Done",
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              Center(
                                child: GestureDetector(
                                  onTap: () {
                                    pickImage();
                                  },
                                  child: Container(
                                    width: 150,
                                    height: 150,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                    child: Center(
                                      child: pickedImage != null
                                          ? ClipOval(
                                              child: Image.file(
                                                pickedImage!,
                                                fit: BoxFit.cover,
                                                width: 150,
                                                height: 150,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.add,
                                              color: Colors.blue,
                                              size: 40,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 30),
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: _name,
                                      onChanged: (value) {
                                        setState(() {
                                          _name = value;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        labelText: 'First Name',
                                        border: _customBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: _lastName,
                                      onChanged: (value) {
                                        setState(() {
                                          _lastName = value;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        labelText: 'Last Name',
                                        border: _customBorder(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                initialValue: _email,
                                onChanged: (value) {
                                  setState(() {
                                    _email = value;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  border: _customBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                initialValue: _field,
                                onChanged: (value) {
                                  _field = value;
                                },
                                decoration: InputDecoration(
                                  labelText: 'Field',
                                  border: _customBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                initialValue: _dob,
                                onChanged: (value) {
                                  setState(() {
                                    _dob = value;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'Date of Birth',
                                  border: _customBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                initialValue: _phoneNumber,
                                onChanged: (value) {
                                  setState(() {
                                    _phoneNumber = value;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'Phone Number',
                                  border: _customBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                initialValue: _gender,
                                onChanged: (value) {
                                  setState(() {
                                    _gender = value;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'Gender',
                                  border: _customBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                initialValue: _experience,
                                onChanged: (value) {
                                  setState(() {
                                    _experience = value;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'Experience',
                                  border: _customBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                initialValue: _qualification,
                                onChanged: (value) {
                                  setState(() {
                                    _qualification = value;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'Qualification',
                                  border: _customBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: _skills,
                                      onChanged: (value) {
                                        setState(() {
                                          _skills = value;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        labelText: 'Skills',
                                        border: _customBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      pickResume();
                                    },
                                    icon: const Icon(Icons.attach_file),
                                    label: const Text('Add Resume'),
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  _updateUserDetails();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const StudentProfile(),
                                    ),
                                  );
                                },
                                child: const Text('Done'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
          }),
    );
  }
}
