import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:traxx_wepapp/models/guest.dart';
import 'package:traxx_wepapp/services/parsers/file_parser/file_parser_abstract.dart';

/// CsvParser is responsible for parsing CSV files containing guest data.
///
/// It implements the [FileParser] interface and expects the CSV to have exactly
/// 3 columns: "Name", "Email", and "Companions".
///
/// Parsing is "all-or-nothing": if the header is invalid or any row is invalid,
/// a [FormatException] is thrown and no guests are returned.
///
/// Usage:
/// ```dart
/// final parser = CsvParser();
/// final guests = parser.parseFile(file);
/// ```
///
/// Note:
/// - Emails are validated using a simple regex.
/// - "Companions" must be a valid integer.
/// - Leading/trailing whitespace is trimmed.
class CsvParser implements FileParser {
  @override
  List<Guest> parseFile(PlatformFile file) {
    List<String> filteredList = [];
    final content = utf8.decode(file.bytes!);
    final List<String> lines = LineSplitter.split(content).toList();
    final headerElements = lines.first.split(',');

    if (!_validateHeader(headerElements)) {
      throw FormatException(
          'Invalid CSV format. Expected 3 columns -  Name, Email, and Companions.');
    }
    if (!_filterRows(lines.skip(1).toList(), filteredList)) {
      throw FormatException('Invalid data rows found in the CSV file.');
    }
    if (filteredList.isEmpty) {
      throw FormatException('No valid data rows found in the CSV file.');
    }
    return filteredList.map((row) {
      final elements = row.split(',');
      return Guest(
        name: elements[0].trim(),
        email: elements[1].trim(),
        companions: int.parse(elements[2].trim()),
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

  bool _validateRow(String row) {
    final elements = row.split(',');
    if (elements.length != 3) {
      return false;
    }
    //Name, Email, Companions
    if (elements[0].trim().isEmpty) {
      return false;
    }
    if (elements[1].trim().isEmpty ||
        !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(elements[1].trim())) {
      return false;
    }
    //checks if companions is number or empty
    if (elements[2].trim().isEmpty ||
        int.tryParse(elements[2].trim()) == null) {
      return false;
    }
    return true;
  }

  bool _filterRows(List<String> rows, List<String> filteredList) {
    for (var row in rows) {
      if (_validateRow(row)) {
        filteredList.add(row);
      } else {
        return false;
      }
    }
    return true;
  }
}
