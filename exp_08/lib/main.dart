// ==============================================================================
// Course       : 24CS2016 - Building Applications using Flutter
// Student Name : A Arockia Dharshan
// Register No  : URK23CS5090
// Exercise     : Ex. 8 - Searching Information in Google Firestore Database (Student Search)
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
      title: 'Student Search',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const SearchPage(),
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController searchController =
      TextEditingController();

  List<QueryDocumentSnapshot> results = [];
  bool isLoading = false;
  bool hasSearched = false;

  Future<void> searchStudents(String value) async {
    if (value.trim().isEmpty) {
      setState(() {
        results = [];
        hasSearched = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      hasSearched = true;
    });

    try {
      final query = await FirebaseFirestore.instance
          .collection('students')
          .where('name',
              isGreaterThanOrEqualTo: value.trim())
          .where('name',
              isLessThanOrEqualTo: '${value.trim()}\uf8ff')
          .get();

      setState(() {
        results = query.docs;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: $e')),
      );
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Search'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search student by name',
                hintText: 'e.g. A Arockia Dharshan',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    searchStudents('');
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: searchStudents,
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: () =>
                  searchStudents(searchController.text),
              icon: const Icon(Icons.search),
              label: const Text('Search'),
            ),

            const SizedBox(height: 20),

            const Text(
              'Search Results',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : !hasSearched
                      ? const Center(
                          child: Text(
                            'Enter a student name to search',
                          ),
                        )
                      : results.isEmpty
                          ? const Center(
                              child: Text(
                                'No matching students found',
                              ),
                            )
                          : ListView.builder(
                              itemCount: results.length,
                              itemBuilder: (context, index) {
                                final data = results[index].data()
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
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
