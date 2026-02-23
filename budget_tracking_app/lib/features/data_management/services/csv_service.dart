import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class CsvService {
  /// Converts a list of data rows to a CSV string.
  static String listToCsv(List<List<dynamic>> rows) {
    return const ListToCsvConverter().convert(rows);
  }

  /// Parses a CSV string into a list of data rows.
  static List<List<dynamic>> csvToList(String csvString) {
    return const CsvToListConverter().convert(csvString);
  }

  /// Saves CSV data to a temporary file and shares it.
  static Future<void> exportAndShareCsv({
    required String filename,
    required List<List<dynamic>> rows,
  }) async {
    final String csvData = listToCsv(rows);
    final Directory directory = await getTemporaryDirectory();
    final String path = '${directory.path}/$filename.csv';
    final File file = File(path);

    await file.writeAsString(csvData);

    final xFile = XFile(path);
    await Share.shareXFiles([xFile], text: 'Financial Data Export: $filename');
  }
}
