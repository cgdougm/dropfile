import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_selector/file_selector.dart';
import 'package:file_picker/file_picker.dart';
import 'file_ops.dart';


void main() async {
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
  AppPageState createState() => AppPageState();
}

class AppPageState extends State<AppPage> {

  List<XFile> ingestedFiles = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ingested Files: ${ingestedFiles.length}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ingestedFiles.isEmpty
                ? Center(child: Text('No files ingested yet'))
                : ListView.builder(
                    itemCount: ingestedFiles.length,
                    itemBuilder: (context, index) {
                      return FutureBuilder<Widget>(
                        future: Future.value(_createFileCard(ingestedFiles[index])),
                        builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
                          if (snapshot.connectionState == ConnectionState.done) {
                            return snapshot.data ?? Container();
                          } else {
                            return CircularProgressIndicator();
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _selectAndProcessFile(context),
        child: Icon(Icons.file_open),
        tooltip: 'Select File',
      ),
    );
  }

  Icon _getIconForMimeType(String mimeType) {
    if (mimeType.startsWith('text/')) {
      return const Icon(Icons.text_snippet);
    } else if (mimeType.startsWith('image/')) {
      return const Icon(Icons.image);
    } else {
      return const Icon(Icons.file_present);
    }
  }

  Widget _createFileCard(XFile xfile) {
    if (xfile.path.isEmpty) {
      return const Text('path empty');
    }
    return FutureBuilder<Map<String, dynamic>>(
      future: fileInfo(xFile: xfile),
      builder:
          (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          final metadata = snapshot.data!;
          final Icon icon = _getIconForMimeType(metadata['mimetype']);

          return ListTile(
            leading: icon,
            title: Text(xfile.name,
                style: const TextStyle(fontFamily: 'RobotoMono', fontSize: 14)),
            subtitle: Text(metadata['fileFolder']),
            trailing: Text(metadata['lastModifiedAgo']),
          );
        } else {
          return const Text('No data');
        }
      },
    );
  }

  void _selectAndProcessFile(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      XFile xfile = XFile(result.files.single.path!);
      setState(() {
        ingestedFiles.add(xfile);
        print("File added. Current list size: ${ingestedFiles.length}");
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ingested ${xfile.name}. Total files: ${ingestedFiles.length}'),
          backgroundColor: Colors.grey[700],
        ),
      );
    } else {
      // User canceled the picker
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No file selected', style: TextStyle(color: Colors.black),), 
          backgroundColor: Colors.amber,
        ),
      );
    }
  }
}
