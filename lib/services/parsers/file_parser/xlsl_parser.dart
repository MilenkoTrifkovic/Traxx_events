import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:traxx_wepapp/models/guest_dart.dart';
import 'package:traxx_wepapp/services/parsers/file_parser/file_parser_abstract.dart';

/// XlsXParser is responsible for parsing XLSX files containing guest data.
///
/// It implements the [FileParser] interface and expects the Excel sheet to have
/// exactly 3 columns: "Name", "Email", and "Companions".
///
/// Parsing is strict — if the header or any row is invalid, a [FormatException]
/// is thrown and no data is returned.
///
/// Behavior:
/// - Only the first sheet in the workbook is processed.
/// - Empty rows are ignored.
/// - Emails are validated with a simple regex.
/// - "Companions" must be a valid integer.
///
/// Usage:
/// ```dart
/// final parser = XlsXParser();
/// final guests = parser.parseFile(file);
/// ```
class XlsXParser implements FileParser {
  @override
  List<Guest_old> parseFile(PlatformFile filePath) {
    if (filePath.bytes == null || filePath.bytes!.isEmpty) {
      throw FormatException('The provided XLSX file is empty or corrupted.');
    }

    final List<List<String>> filteredList = [];
    late final List<String> headerElements;

    final excelFile = Excel.decodeBytes(filePath.bytes!);
    final firstSheet = excelFile.tables[excelFile.tables.keys.first];

    if (firstSheet == null) {
      throw FormatException(
          'Invalid XLSX format. Expected at least 3 columns: Name, Email, and Companions.');
    }
    final rawRows = firstSheet.rows
        .where((row) =>
            row.any((cell) => cell?.value != null)) //eliminate empty rows
        .toList();
    final valuesRows = rawRows //convert Data? to String List<List<String>>
        .map((row) => row.map((cell) => cell?.value?.toString() ?? '').toList())
        .toList();

    headerElements = valuesRows.first;
    if (!_validateHeader(headerElements)) {
      throw FormatException(
          'Invalid XLSX format. Expected 3 columns: Name, Email, and Companions.');
    }
    if (!_filterRows(valuesRows.skip(1).toList(), filteredList)) {
      throw FormatException('Invalid data rows found in the XLSX file.');
    }
    if (filteredList.isEmpty) {
      throw FormatException('No valid data rows found in the XLSX file.');
    }
    return filteredList.map((row) {
      return Guest_old(
        name: row[0].trim(),
        email: row[1].trim(),
        companions: int.parse(row[2].trim()),
      );
    }).toList();
  }

  bool _validateHeader(List<String> headerElements) {
    if (headerElements.length != 3) {
      return false;
    }
    if (headerElements[0].trim().toLowerCase() != 'name' ||
        headerElements[1].trim().toLowerCase() != 'email' ||
        headerElements[2].trim().toLowerCase() != 'companions') {
      return false;
    }
    return true;
  }

  bool _filterRows(List<List<String>> rows, List<List<String>> filteredList) {
    for (var row in rows) {
      if (_validateRow(row)) {
        filteredList.add(row);
      } else {
        return false;
      }
    }
    return true;
  }

  bool _validateRow(List<String> row) {
    // final elements = row.split(',');
    if (row.length != 3) {
      return false;
    }
    //Name, Email, Companions
    if (row[0].trim().isEmpty) {
      return false;
    }
    if (row[1].trim().isEmpty ||
        !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(row[1].trim())) {
      return false;
    }
    //checks if companions is number or empty
    if (row[2].trim().isEmpty || int.tryParse(row[2].trim()) == null) {
      return false;
    }
    return true;
  }
}
