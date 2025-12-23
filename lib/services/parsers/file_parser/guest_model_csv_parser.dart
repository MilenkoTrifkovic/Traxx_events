import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:traxx_wepapp/models/guest_model.dart';
import 'package:traxx_wepapp/utils/enums/genders.dart';

/// GuestModelCsvParser is responsible for parsing CSV files containing guest data.
///
/// It parses CSV files and returns a list of [GuestModel] objects.
/// The CSV must have a header row with column names.
///
/// Required columns: "Name", "Email"
/// Optional columns: "Max Invite", "Address", "City", "State", "Country", "Gender"
///
/// Features:
/// - Handles CSV exports from Excel, Numbers, Google Sheets, etc.
/// - Detects and skips index/row number columns automatically
/// - Normalizes headers (handles variations like "e-mail", "E-Mail", etc.)
/// - Properly handles quoted fields with commas
/// - Validates emails and required fields
/// - Provides detailed row-by-row error messages
///
/// Usage:
/// ```dart
/// final parser = GuestModelCsvParser(eventId: 'event123');
/// final guests = parser.parseFile(file);
/// ```
class GuestModelCsvParser {
  final String eventId;

  GuestModelCsvParser({required this.eventId});

  List<GuestModel> parseFile(PlatformFile file) {
    if (file.bytes == null || file.bytes!.isEmpty) {
      throw FormatException('The provided CSV file is empty or corrupted.');
    }

    final content = utf8.decode(file.bytes!);

    // Use csv package for proper CSV parsing (handles quoted fields, commas in values, etc.)
    final csvData = const CsvToListConverter().convert(content);

    if (csvData.isEmpty) {
      throw FormatException('CSV file is empty.');
    }

    // Step 1: Normalize all rows to strings
    final normalizedRows = csvData.map((row) {
      return row.map((cell) => _cellToString(cell)).toList();
    }).toList();

    // Step 2: Filter out completely empty rows
    final nonEmptyRows = normalizedRows.where((row) {
      return row.any((cell) => cell.isNotEmpty);
    }).toList();

    if (nonEmptyRows.isEmpty) {
      throw FormatException('No data found in the CSV file.');
    }

    // Step 3: Detect and handle index column
    final headerRow = nonEmptyRows.first;
    final hasIndexColumn = _isIndexColumn(headerRow);
    final columnOffset = hasIndexColumn ? 1 : 0;

    // Step 4: Extract data columns (skip index if present)
    final dataRows = nonEmptyRows.map((row) {
      if (columnOffset > 0 && row.length > columnOffset) {
        return row.sublist(columnOffset);
      }
      return row;
    }).toList();

    // Step 5: Ensure all rows have the same length (pad with empty strings)
    final maxColumns =
        dataRows.map((r) => r.length).reduce((a, b) => a > b ? a : b);
    final paddedRows = dataRows.map((row) {
      if (row.length < maxColumns) {
        return [...row, ...List.filled(maxColumns - row.length, '')];
      }
      return row;
    }).toList();

    // Step 6: Parse and normalize headers
    final rawHeaders = paddedRows.first;
    final normalizedHeaders =
        rawHeaders.map((h) => _normalizeHeader(h)).toList();
    final headerMap = <String, int>{};

    for (int i = 0; i < normalizedHeaders.length; i++) {
      final normalized = normalizedHeaders[i];
      if (normalized.isNotEmpty) {
        headerMap[normalized] = i;
      }
    }

    final valuesRows = paddedRows;

    // Validate required columns
    if (!headerMap.containsKey('name') || !headerMap.containsKey('email')) {
      throw FormatException(
          'Invalid CSV format. Required columns: Name, Email. Optional: Max Invite, Address, City, State, Country, Gender.');
    }

    final nameIdx = headerMap['name']!;
    final emailIdx = headerMap['email']!;
    final maxInviteIdx = headerMap['max invite'] ?? headerMap['maxinvite'];
    final addressIdx = headerMap['address'];
    final cityIdx = headerMap['city'];
    final stateIdx = headerMap['state'];
    final countryIdx = headerMap['country'];
    final genderIdx = headerMap['gender'];

    // Parse data rows
    final List<GuestModel> guests = [];
    final List<String> failedRows = [];

    for (int i = 1; i < valuesRows.length; i++) {
      final elements = valuesRows[i];

      // Get actual row number (accounting for header row)
      final rowNumber = i + 1;

      // Validate row has minimum required columns
      if (elements.length <= nameIdx || elements.length <= emailIdx) {
        // Skip this row silently if it's truly empty (no validation error)
        continue;
      }

      final name = elements[nameIdx];
      final email = elements[emailIdx];

      // Skip rows where both Name and Email are empty (empty rows for UX)
      // This allows users to have empty placeholder rows in the template
      if (name.isEmpty && email.isEmpty) {
        continue;
      }

      // Now validate: if the row has any data, both Name and Email are required
      bool hasError = false;
      String errorDetails = '';

      if (name.isEmpty) {
        hasError = true;
        errorDetails = 'Name is empty';
      }

      if (email.isEmpty) {
        hasError = true;
        if (errorDetails.isNotEmpty) errorDetails += ', ';
        errorDetails += 'Email is empty';
      } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
        hasError = true;
        if (errorDetails.isNotEmpty) errorDetails += ', ';
        errorDetails += 'Invalid email format';
      }

      if (hasError) {
        failedRows.add('Row $rowNumber: $errorDetails');
        continue;
      }

      // Extract optional fields - set to null if invalid or empty
      String? address;
      if (addressIdx != null && elements.length > addressIdx) {
        address = elements[addressIdx].isEmpty ? null : elements[addressIdx];
      }

      String? city;
      if (cityIdx != null && elements.length > cityIdx) {
        city = elements[cityIdx].isEmpty ? null : elements[cityIdx];
      }

      String? state;
      if (stateIdx != null && elements.length > stateIdx) {
        state = elements[stateIdx].isEmpty ? null : elements[stateIdx];
      }

      String? country;
      if (countryIdx != null && elements.length > countryIdx) {
        country = elements[countryIdx].isEmpty ? null : elements[countryIdx];
      }

      // Parse Max Invite - default to 0 if empty or invalid
      int maxGuestInvite = 0;
      if (maxInviteIdx != null && elements.length > maxInviteIdx) {
        final maxInviteStr = elements[maxInviteIdx].trim();
        if (maxInviteStr.isNotEmpty) {
          final parsed = int.tryParse(maxInviteStr);
          if (parsed != null && parsed >= 0) {
            maxGuestInvite = parsed;
          }
        }
      }

      Gender? gender;
      if (genderIdx != null && elements.length > genderIdx) {
        final genderStr = elements[genderIdx].toLowerCase();
        if (genderStr.isNotEmpty) {
          gender = _parseGender(genderStr);
          // If parsing fails, gender will be null (no error thrown)
        }
      }

      guests.add(GuestModel(
        name: name,
        email: email,
        eventId: eventId,
        address: address,
        city: city,
        state: state,
        country: country,
        gender: gender,
        maxGuestInvite: maxGuestInvite,
        isDisabled: false,
        isInvited: false,
      ));
    }

    // If there were any failed rows, throw detailed error
    if (failedRows.isNotEmpty) {
      final errorMessage =
          'Upload failed. Invalid data in:\n${failedRows.join('\n')}';
      throw FormatException(errorMessage);
    }

    if (guests.isEmpty) {
      throw FormatException('No valid guest data found in the CSV file.');
    }

    return guests;
  }

  Gender? _parseGender(String genderStr) {
    final lower = genderStr.toLowerCase().trim();

    // Try matching by enum name
    try {
      return Gender.values.firstWhere(
        (g) => g.name.toLowerCase() == lower,
        orElse: () {
          // Additional mapping for common variants
          if (lower == 'm' || lower == 'male') return Gender.male;
          if (lower == 'f' || lower == 'female') return Gender.female;
          if (lower == 'prefer_not_to_say' ||
              lower == 'prefernotto' ||
              lower == 'prefer not to say' ||
              lower == 'other') {
            return Gender.preferNotToSay;
          }
          // Return null for unrecognized values
          throw Exception();
        },
      );
    } catch (_) {
      // Return null if cannot parse
      return null;
    }
  }

  /// Safely converts a cell value to a trimmed string
  /// Handles various data types from CSV parsing
  String _cellToString(dynamic cell) {
    if (cell == null) return '';

    try {
      final cellValue = cell.toString().trim();
      // Remove non-breaking spaces and other unicode whitespace
      return cellValue
          .replaceAll('\u00A0', ' ')
          .replaceAll('\u202F', ' ')
          .replaceAll('\u2009', ' ')
          .replaceAll('\t', ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    } catch (e) {
      return '';
    }
  }

  /// Detects if the first column is an index/row number column
  /// This handles CSV exports from Apple Numbers, Excel, and Google Sheets
  bool _isIndexColumn(List<String> headerRow) {
    if (headerRow.isEmpty) return false;

    final firstCell = headerRow[0].trim().toLowerCase();

    // Empty first cell usually indicates an index column
    if (firstCell.isEmpty) return true;

    // Check for common index column indicators
    if (firstCell == '#' ||
        firstCell == 'no' ||
        firstCell == 'no.' ||
        firstCell == 'num' ||
        firstCell == 'number' ||
        firstCell == 'row' ||
        firstCell == 'index' ||
        firstCell == 'id') {
      return true;
    }

    // Check if it's purely numeric (likely a row number)
    if (int.tryParse(firstCell) != null || double.tryParse(firstCell) != null) {
      return true;
    }

    // If first cell doesn't look like a real column name, it's probably an index
    // Real columns should be at least 2 characters and contain letters
    if (firstCell.length < 2 || !RegExp(r'[a-z]').hasMatch(firstCell)) {
      return true;
    }

    return false;
  }

  /// Normalizes header text for consistent matching across different CSV sources
  /// Handles Apple Numbers, Google Sheets, and Excel variations
  String _normalizeHeader(String header) {
    String normalized = header.toLowerCase().trim();

    // Replace various types of spaces with regular space
    normalized = normalized
        .replaceAll('\u00A0', ' ') // non-breaking space
        .replaceAll('\u202F', ' ') // narrow no-break space
        .replaceAll('\u2009', ' ') // thin space
        .replaceAll('\t', ' '); // tab

    // Collapse multiple spaces
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');

    // Handle common variations
    final variations = {
      'e-mail': 'email',
      'e mail': 'email',
      'mail': 'email',
      'full name': 'name',
      'guest name': 'name',
      'street': 'address',
      'street address': 'address',
      'zip': 'state',
      'postal code': 'state',
      'sex': 'gender',
    };

    return variations[normalized] ?? normalized;
  }
}
