import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_selector/file_selector.dart';
import 'package:file_picker/file_picker.dart';
import 'file_ops.dart';
import 'package:provider/provider.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  // Wait for initial load
  await Future.delayed(Duration(milliseconds: 100)); // Give time for DB load

  runApp(
    ChangeNotifierProvider(
      create: (context) => appState,
      child: AppWidget(),
    ),
  );
}

class AppWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dropzone App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DropTarget(
        onDragDone: (detail) {
          print("Drag done with ${detail.files}");
          _handleDroppedFiles(context, detail.files);
        },
        child: AppPageWidget(),
      ),
    );
  }

  void _handleDroppedFiles(BuildContext context, List<XFile> files) {
    final appState = Provider.of<AppState>(context, listen: false);
    final existingFiles = appState.filterExistingFiles(files);
    final newFiles = appState.filterNewFiles(files);

    if (existingFiles.isNotEmpty) {
      // Show warning for duplicate files
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Duplicate Files Detected'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${existingFiles.length} out of ${files.length} files are already ingested:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                ...existingFiles.map((file) => Text('• ${file.name}')),
                SizedBox(height: 16),
                Text('The drop operation has been cancelled.'),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else if (newFiles.isNotEmpty) {
      // Show confirmation for new files
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Add Files?'),
            content: Text('Do you want to add ${newFiles.length} file(s)?'),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Add'),
                onPressed: () {
                  appState.handleDroppedFiles(newFiles);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }
}

/// The single-page-app page
class AppPageWidget extends StatelessWidget {
  const AppPageWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Ingested ${appState.files.length} files'),
            actions: [
              IconButton(
                onPressed: () async {
                  final bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Reset Database'),
                        content: const Text(
                            'Are you sure you want to clear all files?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Reset'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirm == true) {
                    await appState.clearAllFiles();
                  }
                },
                icon: const Icon(Icons.delete_forever),
                tooltip: 'Reset Database',
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              ),
              IconButton(
                onPressed: () => _selectAndProcessFile(context),
                icon: const Icon(Icons.add),
                tooltip: 'Add File',
                padding: const EdgeInsets.fromLTRB(10, 0, 40, 0),
                color: Colors.blueAccent,
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: appState.files.isEmpty
                    ? Center(child: Text('No files ingested yet'))
                    : ListView.builder(
                        itemCount: appState.files.length,
                        itemBuilder: (context, index) {
                          return FutureBuilder<Widget>(
                            future: Future.value(
                                _createFileCard(appState.files[index])),
                            builder: (BuildContext context,
                                AsyncSnapshot<Widget> snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.done) {
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
        );
      },
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

          final String subtitle =
              '${metadata['lastModifiedFormatted']} (${metadata['lastModifiedAgo']}) ${metadata['fileLengthFormatted']}';
          return ListTile(
            leading: icon,
            title: Text(xfile.name,
                style: const TextStyle(
                    fontFamily: 'HeptaSlab',
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            subtitle: Text(subtitle),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onSelected: (String choice) async {
                switch (choice) {
                  case 'locate':
                    final path = xfile.path;
                    Process.run('explorer.exe', ['/select,', path]);
                    break;
                  case 'remove':
                    await Provider.of<AppState>(context, listen: false)
                        .removeFile(xfile);
                    break;
                  case 'info':
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(xfile.name),
                          content: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Path: ${metadata['filePath']}'),
                                Text('Folder: ${metadata['fileFolder']}'),
                                Text(
                                    'Size: ${metadata['fileLengthFormatted']}'),
                                Text('MIME Type: ${metadata['mimetype']}'),
                                Text(
                                    'Modified: ${metadata['lastModifiedFormatted']}'),
                                Text('Hash: ${metadata['fileHash']}'),
                                if (metadata['imageDimensionsFormatted'] !=
                                    null)
                                  Text(
                                      'Dimensions: ${metadata['imageDimensionsFormatted']}'),
                                if (metadata['textContent'] != null)
                                  Text(
                                      'Preview: ${metadata['textContent'].substring(0, metadata['textContent'].length.clamp(0, 100))}...'),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        );
                      },
                    );
                    break;
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'locate',
                  child: ListTile(
                    leading: Icon(Icons.folder_open),
                    title: Text('Locate in Explorer'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'remove',
                  child: ListTile(
                    leading: Icon(Icons.delete),
                    title: Text('Remove from Database'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'info',
                  child: ListTile(
                    leading: Icon(Icons.info),
                    title: Text('More Info'),
                  ),
                ),
              ],
            ),
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
      Provider.of<AppState>(context, listen: false).addFile(xfile);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ingested ${xfile.name}'),
          backgroundColor: Colors.grey[700],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No file selected',
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.amber,
        ),
      );
    }
  }
}
