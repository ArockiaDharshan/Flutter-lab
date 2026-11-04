// ==============================================================================
// Course       : 24CS2016 - Building Applications using Flutter
// Student Name : A Arockia Dharshan
// Register No  : URK23CS5090
// Exercise     : Ex. 7 - Data Persistence Using Google Cloud Firestore (StudentHub Cloud)
// GitHub       : https://github.com/ArockiaDharshan
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StudentHub Cloud',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const StudentPage(),
    );
  }
}

class StudentPage extends StatefulWidget {
  const StudentPage({super.key});

  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  final nameController = TextEditingController();
  final registerController = TextEditingController();
  final departmentController = TextEditingController();
  final emailController = TextEditingController();

  final CollectionReference students =
      FirebaseFirestore.instance.collection('students');

  Future<void> addStudent() async {
    if (nameController.text.isEmpty ||
        registerController.text.isEmpty ||
        departmentController.text.isEmpty ||
        emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    await students.add({
      'name': nameController.text.trim(),
      'registerNumber': registerController.text.trim(),
      'department': departmentController.text.trim(),
      'email': emailController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    nameController.clear();
    registerController.clear();
    departmentController.clear();
    emailController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Student saved successfully!')),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    registerController.dispose();
    departmentController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StudentHub Cloud'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Student Name',
                hintText: 'e.g. A Arockia Dharshan',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: registerController,
              decoration: const InputDecoration(
                labelText: 'Register Number',
                hintText: 'e.g. URK23CS5090',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: departmentController,
              decoration: const InputDecoration(
                labelText: 'Department',
                hintText: 'e.g. CSE(AI)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'e.g. aarockia@karunya.edu.in',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            ElevatedButton.icon(
              onPressed: addStudent,
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Save Student'),
            ),

            const Divider(height: 30),

            const Text(
              'Registered Students',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: students
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  final studentList = snapshot.data!.docs;

                  if (studentList.isEmpty) {
                    return const Center(
                      child: Text('No students registered yet'),
                    );
                  }

                  return ListView.builder(
                    itemCount: studentList.length,
                    itemBuilder: (context, index) {
                      final data = studentList[index].data()
                          as Map<String, dynamic>;

                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(data['name']),
                          subtitle: Text(
                            'Register No: ${data['registerNumber']}\n'
                            'Department: ${data['department']}\n'
                            'Email: ${data['email']}',
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
