import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/widgets.dart';
import 'package:file_picker/file_picker.dart';
// import 'dart:typed_data';  // Removed unused import

void main() async {
  // CLI Testing:
  // WidgetsFlutterBinding.ensureInitialized();
  // demoFileOperations(filePath: 'assets/hello.txt');
  // demoFileOperations(xFile: XFile('assets/image_house.jpg'));
  // demoFileOperations(filePath: 'assets/folder-1484.png');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dropzone',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AppPage(),
    );
  }
}

class AppPage extends StatefulWidget {
  const AppPage({Key? key}) : super(key: key);

  @override
  _AppPageState createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  List<String> ingestFilePaths = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text('files:', style: TextStyle(fontFamily: 'HeptaSlab', fontSize: 30, letterSpacing: -1.0)),
          ...ingestFilePaths.map((path) => createFileCard(path)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _selectAndProcessFile(context),
        child: Icon(Icons.file_open),
        tooltip: 'Select File',
      ),
    );
  }

  Widget createFileCard(String path) {
    // Implement your file card widget here
    return ListTile(
      title: Text(path, style: TextStyle(fontFamily: 'RobotoMono', fontSize: 14)),
      // Add more details or customize as needed
    );
  }

  void _selectAndProcessFile(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      XFile xfile = XFile(result.files.single.path!);
      // await demoFileOperations(xFile: xfile);
      ingestFilePaths.add(xfile.path);
      setState(() {});
    } else {
      // User canceled the picker
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No file selected')),
      );
    }
  }
}
