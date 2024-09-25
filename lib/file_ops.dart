import 'dart:io';
import 'package:mime/mime.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:cross_file/cross_file.dart';
import 'package:intl/intl.dart'; // Added for date formatting

/// Returns a formatted date string for a given date, with the
///  option to include "ago" format
String formatDateTime(DateTime date, {bool withAgo = false}) {
  final formatter = DateFormat('EEE MMM d, yyyy h:mm a');
  final formattedDate = formatter.format(date);
  if (!withAgo) return formattedDate;
  
  final timeAgo = getTimeAgo(date);
  return '$formattedDate ($timeAgo)';
}

/// Returns a string with the time "ago format" for a given date
String getTimeAgo(DateTime date) {
  final difference = DateTime.now().difference(date);
  if (difference.inDays > 0) return '${difference.inDays} days ago';
  if (difference.inHours > 0) return '${difference.inHours} hours ago';
  if (difference.inMinutes > 0) return '${difference.inMinutes} minutes ago';
  return 'just now';
}

/// Returns a future map with file information:
/// 
///  * [xFile]: the XFile object
///  * [filePath]: the full file path
///  * [fileName]: the file name portion of the path
///  * [fileExt]: the file extension 
///  * [fileFolder]: the parent file folder portion of the path
///  * [mimetype]: the mime type string
///  * [fileLength]: the file length in bytes
///  * [lastModified]: the last modified date object
///  * [lastModifiedFormatted]: the last modified date formatted
///  * [lastModifiedAgo]: the last modified date in "x ago" format
///  * [textContent]: the text content of the file if it is a text file
///  * [image]: the decoded image data
///  * [imageDimensions]: the image dimensions, width and height
///  * [imageError]: the error message if there is an error decoding the image
/// 
Future<Map<String, dynamic>> fileInfo({String? filePath, XFile? xFile}) async {
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

  result['xFile'] = fileToProcess;
  result['filePath'] = fileToProcess.path;
  result['fileName'] = path.basename(fileToProcess.path);
  result['fileExt'] = path.extension(fileToProcess.path);
  result['fileFolder'] = path.dirname(fileToProcess.path);

  final File file = File(fileToProcess.path);
  final String? mimeType = lookupMimeType(file.path);
  result['mimetype'] = mimeType ?? 'Unknown';

  final int fileLength = await fileToProcess.length();
  result['fileLength'] = '$fileLength bytes';

  final DateTime lastModified = await file.lastModified();
  result['lastModified'] = lastModified;
  final String formattedDate = formatDateTime(lastModified, withAgo: false);
  result['lastModifiedFormatted'] = formattedDate;
  result['lastModifiedAgo'] = getTimeAgo(lastModified);

  if (mimeType?.startsWith('text/') == true) {
    final String fileContent = await fileToProcess.readAsString();
    result['textContent'] = fileContent;
  } else if (mimeType?.startsWith('image/') == true) {
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      result['image'] = image;
      result['imageDimensions'] =[image?.width, image?.height];
      result['imageDimensionsFormatted'] = '${image?.width} x ${image?.height}';
    } catch (e) {
      result['imageError'] = 'Error decoding image: $e';
    }
  }

  return result;
}
