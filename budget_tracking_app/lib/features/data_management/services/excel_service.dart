import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExcelService {
  /// Generates an Excel workbook from the provided data sheets.
  /// [sheets] is a map where key is the sheet name and value is the list of rows.
  static Future<void> exportAndShareExcel({
    required String filename,
    required Map<String, List<List<dynamic>>> sheets,
  }) async {
    final excel = Excel.createExcel();

    // Default sheet is usually 'Sheet1', we'll rename it or remove it
    excel.rename('Sheet1', sheets.keys.first);

    for (var entry in sheets.entries) {
      final sheetName = entry.key;
      final rows = entry.value;

      Sheet sheetObject = excel[sheetName];

      for (var row in rows) {
        sheetObject.appendRow(row.map((e) {
          if (e == null) return null;
          if (e is int) return IntCellValue(e);
          if (e is double) return DoubleCellValue(e);
          if (e is bool) return BoolCellValue(e);
          if (e is DateTime) {
            return DateCellValue(year: e.year, month: e.month, day: e.day);
          }
          return TextCellValue(e.toString());
        }).toList());
      }
    }

    final fileBytes = excel.encode();
    if (fileBytes == null) {
      return;
    }

    final Directory directory = await getTemporaryDirectory();
    final String path = '${directory.path}/$filename.xlsx';
    final File file = File(path);

    await file.writeAsBytes(fileBytes);

    final xFile = XFile(path);
    await Share.shareXFiles([xFile], text: 'Financial Data Export: $filename');
  }
}
