import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/widgets.dart';
import 'dart:io';

demoFileOperations(String filePath) async {
  final XFile file = XFile(filePath);

  print('File information:');
  print('- Path: ${file.path}');
  print('- Name: ${file.name}');
  print('- MIME type: ${file.mimeType}');

  final String fileContent = await file.readAsString();
  print('Content of the file: $fileContent');

  const XTypeGroup typeGroup = XTypeGroup(
    label: 'images',
    extensions: <String>['jpg', 'png'],
  );
  final XFile? selectedFile =
      await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
  print('File information:');
  print('- Path: ${selectedFile?.path}');
  print('- Name: ${selectedFile?.name}');
  print('- Mimetype: ${selectedFile?.mimeType}');
  if (selectedFile != null) {
    final int fileLength = await selectedFile.length();
    print('File length: $fileLength bytes');
    final File file = File(selectedFile.path);
    final DateTime lastModified = await file.lastModified();
    print('File last modified: $lastModified');
  }
}

class DroppedFileCard extends StatelessWidget {
  final String filePath;

  const DroppedFileCard({Key? key, required this.filePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.file_present),
        title: Text(filePath),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  demoFileOperations('assets/hello.txt');
  // runApp(const MyApp());
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

class AppPage extends StatelessWidget {
  const AppPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text(
            'Dropzone',
          ),
          // Your existing cards
          // New cards will be added here
        ],
      ),
    );
  }

  void _handleDroppedFiles(List<XFile> files) {
    // Handle the list of XFile objects
    print('Files dropped: ${files}');
  }
}
