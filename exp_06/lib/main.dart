// ==============================================================================
// Course       : 24CS2016 - Building Applications using Flutter
// Student Name : A Arockia Dharshan
// Register No  : URK23CS5090
// Exercise     : Ex. 6 - Data Persistence Using SQLite (StudentHub Local Database)
// GitHub       : https://github.com/ArockiaDharshan
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart' as p;

// MAIN FUNCTION
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure SQLite for Chrome
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  runApp(const StudentHubApp());
}

// STUDENT MODEL
class Student {
  final int? id;
  final String name;
  final String registerNumber;
  final String department;
  final String email;

  Student({
    this.id,
    required this.name,
    required this.registerNumber,
    required this.department,
    required this.email,
  });

  // Convert Student object into a Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'registerNumber': registerNumber,
      'department': department,
      'email': email,
    };
  }

  // Convert database Map into Student object
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as int,
      name: map['name'] as String,
      registerNumber: map['registerNumber'] as String,
      department: map['department'] as String,
      email: map['email'] as String,
    );
  }
}

// DATABASE HELPER CLASS
class DatabaseHelper {

  static final DatabaseHelper instance =
      DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  // OPEN DATABASE
  Future<Database> get database async {

    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();

    return _database!;
  }

  // INITIALIZE DATABASE
  Future<Database> _initDatabase() async {

    final String databasePath;

    if (kIsWeb) {
      databasePath = 'studenthub.db';
    } else {
      final path = await getDatabasesPath();
      databasePath = p.join(path, 'studenthub.db');
    }

    return await openDatabase(
      databasePath,
      version: 1,

      // CREATE STUDENTS TABLE
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE students (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            registerNumber TEXT NOT NULL,
            department TEXT NOT NULL,
            email TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // CREATE: INSERT STUDENT
  Future<int> insertStudent(Student student) async {

    final db = await database;

    return await db.insert(
      'students',
      student.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // READ: GET ALL STUDENTS
  Future<List<Student>> getStudents() async {

    final db = await database;

    final List<Map<String, dynamic>> maps =
        await db.query(
      'students',
      orderBy: 'id DESC',
    );

    return List.generate(
      maps.length,
      (index) => Student.fromMap(maps[index]),
    );
  }
}

// MAIN APPLICATION
class StudentHubApp extends StatelessWidget {
  const StudentHubApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StudentHub',

      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),

      home: const StudentHomePage(),
    );
  }
}

// STUDENT HOME PAGE
class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() =>
      _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {

  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final registerController = TextEditingController();
  final departmentController = TextEditingController();
  final emailController = TextEditingController();

  List<Student> students = [];

  bool isLoading = true;
  bool isSaving = false;

  // LOAD STUDENTS FROM DATABASE
  @override
  void initState() {
    super.initState();
    loadStudents();
  }

  Future<void> loadStudents() async {

    try {
      final data =
          await DatabaseHelper.instance.getStudents();

      if (!mounted) return;

      setState(() {
        students = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showMessage('Error loading students: $e');
    }
  }

  // SAVE STUDENT
  Future<void> saveStudent() async {

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    final student = Student(
      name: nameController.text.trim(),
      registerNumber: registerController.text.trim(),
      department: departmentController.text.trim(),
      email: emailController.text.trim(),
    );

    try {
      await DatabaseHelper.instance.insertStudent(student);

      nameController.clear();
      registerController.clear();
      departmentController.clear();
      emailController.clear();

      await loadStudents();

      if (!mounted) return;

      showMessage('Student saved successfully!');
    } catch (e) {
      if (!mounted) return;

      showMessage('Unable to save student: $e');
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // DISPLAY MESSAGE
  void showMessage(String message) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // DISPOSE CONTROLLERS
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
      backgroundColor: const Color(0xFFF4F5FA),

      // APP BAR
      appBar: AppBar(
        title: const Text(
          'StudentHub',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh records',
            icon: const Icon(Icons.refresh),
            onPressed: loadStudents,
          ),
        ],
      ),

      // MAIN BODY
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 750,
          ),

          child: ListView(
            padding: const EdgeInsets.all(18),

            children: [

              // WELCOME BANNER
              Container(
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(15),
                ),

                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      'Student Record Management',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),

                    SizedBox(height: 6),

                    Text(
                      'Add and manage student records '
                      'using SQLite database.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ADD STUDENT FORM
              Card(
                color: Colors.white,
                elevation: 3,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),

                child: Padding(
                  padding: const EdgeInsets.all(18),

                  child: Form(
                    key: _formKey,

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        const Text(
                          'Add New Student',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // STUDENT NAME
                        buildInputField(
                          controller: nameController,
                          label: 'Student Name',
                          hint: 'e.g. A Arockia Dharshan',
                          icon: Icons.person,
                        ),

                        const SizedBox(height: 15),

                        // REGISTER NUMBER
                        buildInputField(
                          controller: registerController,
                          label: 'Register Number',
                          hint: 'e.g. URK23CS5090',
                          icon: Icons.badge,
                        ),

                        const SizedBox(height: 15),

                        // DEPARTMENT
                        buildInputField(
                          controller: departmentController,
                          label: 'Department',
                          hint: 'e.g. CSE(AI)',
                          icon: Icons.school,
                        ),

                        const SizedBox(height: 15),

                        // EMAIL
                        buildInputField(
                          controller: emailController,
                          label: 'Email Address',
                          hint: 'e.g. aarockia@karunya.edu.in',
                          icon: Icons.email,
                          isEmail: true,
                        ),

                        const SizedBox(height: 22),

                        // SAVE BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 48,

                          child: ElevatedButton.icon(
                            onPressed:
                                isSaving ? null : saveStudent,

                            icon: const Icon(Icons.save),

                            label: Text(
                              isSaving
                                  ? 'Saving...'
                                  : 'Save Student',
                            ),

                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // STUDENT RECORDS HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [

                  const Text(
                    'Student Records',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.indigo.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: Text(
                      '${students.length} Students',
                      style: const TextStyle(
                        color: Colors.indigo,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // READ STUDENT RECORDS
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(25),
                    child: CircularProgressIndicator(),
                  ),
                )

              else if (students.isEmpty)
                Container(
                  padding: const EdgeInsets.all(30),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),

                  child: const Column(
                    children: [

                      Icon(
                        Icons.people_outline,
                        size: 55,
                        color: Colors.grey,
                      ),

                      SizedBox(height: 10),

                      Text(
                        'No student records found!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),

                      SizedBox(height: 5),

                      Text(
                        'Add your first student using the form above.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )

              else
                ...students.map(
                  (student) => StudentCard(student: student),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // REUSABLE INPUT FIELD
  Widget buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isEmail = false,
  }) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 7),

        TextFormField(
          controller: controller,

          keyboardType: isEmail
              ? TextInputType.emailAddress
              : TextInputType.text,

          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.indigo),

            filled: true,
            fillColor: const Color(0xFFF8F8FC),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          validator: (value) {

            if (value == null || value.trim().isEmpty) {
              return 'Please enter $label';
            }

            if (isEmail &&
                !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                    .hasMatch(value.trim())) {
              return 'Please enter a valid email';
            }

            return null;
          },
        ),
      ],
    );
  }
}

// REUSABLE STUDENT CARD
class StudentCard extends StatelessWidget {

  final Student student;

  const StudentCard({
    super.key,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {

    return Card(
      color: Colors.white,
      elevation: 2,

      margin: const EdgeInsets.only(bottom: 12),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),

      child: ListTile(

        contentPadding: const EdgeInsets.all(12),

        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.indigo.shade100,

          child: Text(
            student.name.isNotEmpty
                ? student.name[0].toUpperCase()
                : '?',

            style: const TextStyle(
              color: Colors.indigo,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        title: Text(
          student.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),

          child: Text(
            'Register No: ${student.registerNumber}\n'
            'Department: ${student.department}\n'
            'Email: ${student.email}',
          ),
        ),

        isThreeLine: true,

        trailing: const Icon(
          Icons.storage,
          color: Colors.green,
        ),
      ),
    );
  }
}
