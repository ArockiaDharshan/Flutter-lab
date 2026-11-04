// ==============================================================================
// Course       : 24CS2016 - Building Applications using Flutter
// Student Name : A Arockia Dharshan
// Register No  : URK23CS5090
// Exercise     : Ex. 9 - Update Information in Google Firestore Database (Student Record Updater)
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
      title: 'Student Update',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const UpdatePage(),
    );
  }
}

class UpdatePage extends StatefulWidget {
  const UpdatePage({super.key});

  @override
  State<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends State<UpdatePage> {
  final registerController = TextEditingController();
  final nameController = TextEditingController();
  final departmentController = TextEditingController();
  final emailController = TextEditingController();

  final CollectionReference students =
      FirebaseFirestore.instance.collection('students');

  String? documentId;
  bool isLoading = false;

  Future<void> searchStudent() async {
    final registerNumber = registerController.text.trim();

    if (registerNumber.isEmpty) return;

    setState(() {
      isLoading = true;
      documentId = null;
    });

    try {
      final query = await students
          .where('registerNumber', isEqualTo: registerNumber)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data() as Map<String, dynamic>;

        setState(() {
          documentId = doc.id;
          nameController.text = data['name'] ?? '';
          departmentController.text = data['department'] ?? '';
          emailController.text = data['email'] ?? '';
          isLoading = false;
        });
      } else {
        setState(() {
          nameController.clear();
          departmentController.clear();
          emailController.clear();
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student not found')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: $e')),
      );
    }
  }

  Future<void> updateStudent() async {
    if (documentId == null) return;

    try {
      await students.doc(documentId).update({
        'name': nameController.text.trim(),
        'department': departmentController.text.trim(),
        'email': emailController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student updated successfully!'),
        ),
      );

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  @override
  void dispose() {
    registerController.dispose();
    nameController.dispose();
    departmentController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Student Information'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: registerController,
                decoration: const InputDecoration(
                  labelText: 'Enter Register Number',
                  hintText: 'e.g. URK23CS5090',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
              ),

              const SizedBox(height: 12),

              ElevatedButton.icon(
                onPressed: searchStudent,
                icon: const Icon(Icons.search),
                label: const Text('Find Student'),
              ),

              const SizedBox(height: 20),

              if (isLoading)
                const CircularProgressIndicator(),

              if (documentId != null) ...[
                const Text(
                  'Edit Student Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

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
                  controller: departmentController,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: updateStudent,
                  icon: const Icon(Icons.update),
                  label: const Text('Update Student'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
