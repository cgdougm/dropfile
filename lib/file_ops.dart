import 'dart:io';
import 'package:mime/mime.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:cross_file/cross_file.dart';
import 'package:intl/intl.dart'; // Added for date formatting

String formatDateTime(DateTime date, {bool withAgo = false}) {
  final formatter = DateFormat('EEE MMM d, yyyy h:mm a');
  final formattedDate = formatter.format(date);
  if (!withAgo) return formattedDate;
  
  final timeAgo = getTimeAgo(date);
  return '$formattedDate ($timeAgo)';
}

String getTimeAgo(DateTime date) {
  final difference = DateTime.now().difference(date);
  if (difference.inDays > 0) return '${difference.inDays} days ago';
  if (difference.inHours > 0) return '${difference.inHours} hours ago';
  if (difference.inMinutes > 0) return '${difference.inMinutes} minutes ago';
  return 'just now';
}

Future<Map<String, dynamic>> demoFileOperations({String? filePath, XFile? xFile}) async {
  XFile fileToProcess;
  Map<String, dynamic> result = {};

  if (xFile != null) {
    fileToProcess = xFile;
  } else if (filePath != null) {
    String normalizedPath = path.normalize(filePath);
    fileToProcess = XFile(normalizedPath);
  } else {
    throw ArgumentError('Either filePath or xFile must be provided');
  }

  result['path'] = fileToProcess.path;
  result['name'] = path.basename(fileToProcess.path);

  final File file = File(fileToProcess.path);
  final String? mimeType = lookupMimeType(file.path);
  result['mimetype'] = mimeType ?? 'Unknown';

  final int fileLength = await fileToProcess.length();
  result['length'] = '$fileLength bytes';

  final DateTime lastModified = await file.lastModified();
  final String formattedDate = formatDateTime(lastModified, withAgo: true);
  result['lastModified'] = formattedDate;

  if (mimeType?.startsWith('text/') == true) {
    final String fileContent = await fileToProcess.readAsString();
    result['content'] = fileContent;
  } else if (mimeType?.startsWith('image/') == true) {
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      result['imageDimensions'] = '${image?.width} x ${image?.height} pixels';
    } catch (e) {
      result['imageError'] = 'Error decoding image: $e';
    }
  }

  return result;
}
