import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:traxx_wepapp/models/guest_model.dart';
import 'package:traxx_wepapp/utils/enums/genders.dart';

/// GuestModelXlsxParser is responsible for parsing XLSX files containing guest data.
///
/// It parses XLSX files and returns a list of [GuestModel] objects.
/// The first row must be a header with column names.
///
/// Required columns: "Name", "Email"
/// Optional columns: "Max Invite", "Address", "City", "State", "Country", "Gender"
///
/// Parsing is strict — if the header or any required field is missing,
/// a [FormatException] is thrown and no data is returned.
///
/// Behavior:
/// - Only the first sheet in the workbook is processed.
/// - Empty rows are ignored.
/// - Emails are validated with a simple regex.
/// - Gender values are matched case-insensitively against Gender enum values
///
/// Usage:
/// ```dart
/// final parser = GuestModelXlsxParser(eventId: 'event123');
/// final guests = parser.parseFile(file);
/// ```
class GuestModelXlsxParser {
  final String eventId;

  GuestModelXlsxParser({required this.eventId});

  List<GuestModel> parseFile(PlatformFile file) {
    if (file.bytes == null || file.bytes!.isEmpty) {
      throw FormatException('The provided XLSX file is empty or corrupted.');
    }

    final excelFile = Excel.decodeBytes(file.bytes!);
    final firstSheet = excelFile.tables[excelFile.tables.keys.first];

    if (firstSheet == null || firstSheet.rows.isEmpty) {
      throw FormatException(
          'Invalid XLSX format. The file must contain at least a header row.');
    }

    // Filter out completely empty rows
    // Also filter out rows where only the first column (row number) has a value
    final rawRows = firstSheet.rows.where((row) {
      // Skip if row is completely empty
      if (row.every((cell) => cell?.value == null)) return false;

      // Skip if only the first cell (row number column) has a value
      // Check if any cell after the first column has a value
      bool hasDataBeyondFirstColumn = false;
      for (int i = 1; i < row.length; i++) {
        if (row[i]?.value != null) {
          hasDataBeyondFirstColumn = true;
          break;
        }
      }
      return hasDataBeyondFirstColumn;
    }).toList();

    if (rawRows.isEmpty) {
      throw FormatException('No data found in the XLSX file.');
    }

    // Convert to string values - safely handle different cell value types
    // Skip the first column (row number column) when processing
    final valuesRows = rawRows.map((row) {
      return row.skip(1).map((cell) {
        if (cell == null || cell.value == null) return '';

        try {
          final value = cell.value;
          // Handle different cell value types
          if (value is String) return value;
          if (value is num) return value.toString();
          if (value is bool) return value.toString();
          if (value is DateTime) {
            return (value as DateTime).toIso8601String();
          }
          // For any other type, try toString()
          return value.toString();
        } catch (e) {
          // If conversion fails, return empty string
          return '';
        }
      }).toList();
    }).toList();

    // Parse header
    final headerElements =
        valuesRows.first.map((e) => e.toString().trim()).toList();
    final headerMap = <String, int>{};

    for (int i = 0; i < headerElements.length; i++) {
      headerMap[headerElements[i].toLowerCase()] = i;
    }

    // Validate required columns
    if (!headerMap.containsKey('name') || !headerMap.containsKey('email')) {
      throw FormatException(
          'Invalid XLSX format. Required columns: Name, Email. Optional: Max Invite, Address, City, State, Country, Gender.');
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
      final elements = valuesRows[i].map((e) => e.toString().trim()).toList();

      // Get actual row number (accounting for header row and Excel starting at 1)
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
      throw FormatException('No valid guest data found in the XLSX file.');
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
}
