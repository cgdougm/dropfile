import 'package:flutter/foundation.dart';
import 'db_helper.dart';
import 'unique_id.dart';
import 'package:cross_file/cross_file.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

class AppState extends ChangeNotifier {
  final List<XFile> _files = [];
  final List<Uri> _urls = [];

  AppState() {
    _loadStoredItems();
  }

  List<XFile> get files => _files;
  List<Uri> get urls => _urls;

  Future<void> _loadStoredItems() async {
    final items = await DatabaseHelper.instance.getItems();
    for (var item in items) {
      if (item['type'] == 'file') {
        final file = XFile(item['value']);
        if (await File(file.path).exists()) {
          _files.add(file);
        }
      } else if (item['type'] == 'url') {
        _urls.add(Uri.parse(item['value']));
      }
    }
    notifyListeners();
  }

  bool hasFile(XFile file) {
    return _files.any((f) => f.uniqueId == file.uniqueId);
  }

  List<XFile> filterNewFiles(List<XFile> files) {
    return files.where((file) => !hasFile(file)).toList();
  }

  List<XFile> filterExistingFiles(List<XFile> files) {
    return files.where((file) => hasFile(file)).toList();
  }

  void addFile(XFile file) {
    if (!hasFile(file)) {
      _files.add(file);
      DatabaseHelper.instance.insertItem(file.uniqueId, 'file', file.path,
          parent: path.dirname(file.path));
      notifyListeners();
    }
  }

  void addURL(Uri url) {
    if (!_urls.any((u) => u.uniqueId == url.uniqueId)) {
      _urls.add(url);
      DatabaseHelper.instance
          .insertItem(url.uniqueId, 'url', url.toString(), parent: url.host);
      notifyListeners();
    }
  }

  void handleDroppedFiles(List<XFile> xfiles) {
    for (var file in xfiles) {
      addFile(file);
    }
  }

  Future<void> clearAllFiles() async {
    _files.clear();
    await DatabaseHelper.instance.clearAllItems();
    notifyListeners();
  }

  Future<void> removeFile(XFile file) async {
    _files.removeWhere((f) => f.uniqueId == file.uniqueId);
    await DatabaseHelper.instance.deleteItem(file.uniqueId);
    notifyListeners();
  }
}
