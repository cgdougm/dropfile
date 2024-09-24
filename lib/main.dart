import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/widgets.dart';
import 'dart:io';
import 'package:mime/mime.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart'; // Added for date formatting
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';

Future<void> demoFileOperations({String? filePath, XFile? xFile}) async {
  XFile fileToProcess;

  if (xFile != null) {
    fileToProcess = xFile;
  } else if (filePath != null) {
    // Use path.normalize to handle path separators correctly
    String normalizedPath = path.normalize(filePath);
    fileToProcess = XFile(normalizedPath);
  } else {
    throw ArgumentError('Either filePath or xFile must be provided');
  }

  print('File information:');
  print('- Path: ${fileToProcess.path}');
  // Use path.basename to get the file name correctly
  print('- Name: ${path.basename(fileToProcess.path)}');

  final File file = File(fileToProcess.path);
  final String? mimeType = lookupMimeType(file.path);
  print('- Mimetype: ${mimeType ?? 'Unknown'}');

  final int fileLength = await fileToProcess.length();
  print('File length: $fileLength bytes');

  final DateTime lastModified = await file.lastModified();
  final String formattedDate = _formatDateTime(lastModified, withAgo: true);
  print('File last modified: $formattedDate');

  if (mimeType?.startsWith('text/') == true) {
    final String fileContent = await fileToProcess.readAsString();
    print('Content of the text file: "$fileContent"');
  } else if (mimeType?.startsWith('image/') == true) {
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      print('Image dimensions: ${image?.width} x ${image?.height} pixels');
    } catch (e) {
      print('Error decoding image: $e');
    }
  }
}



String _formatDateTime(DateTime date, {bool withAgo = false}) {
  final formatter = DateFormat('EEE MMM d, yyyy h:mm a');
  final formattedDate = formatter.format(date);
  if (!withAgo) return formattedDate;
  
  final timeAgo = _getTimeAgo(date);
  return '$formattedDate ($timeAgo)';
}

String _getTimeAgo(DateTime date) {
  final difference = DateTime.now().difference(date);
  if (difference.inDays > 0) return '${difference.inDays} days ago';
  if (difference.inHours > 0) return '${difference.inHours} hours ago';
  if (difference.inMinutes > 0) return '${difference.inMinutes} minutes ago';
  return 'just now';
}

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

class AppPage extends StatelessWidget {
  const AppPage({Key? key}) : super(key: key);

  void _selectAndProcessFile(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      XFile xfile = XFile(result.files.single.path!);
      await demoFileOperations(xFile: xfile);
    } else {
      // User canceled the picker
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No file selected')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Column(
          children: [
            Text('FILES:'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _selectAndProcessFile(context),
        child: Icon(Icons.file_open),
        tooltip: 'Select File',
      ),
    );
  }
}
