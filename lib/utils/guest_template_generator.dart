import 'dart:typed_data';
import 'package:excel/excel.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:traxx_wepapp/features/admin/admin_guests_management/controllers/admin_guest_list_controller.dart';
import 'package:traxx_wepapp/models/guest_rsvp_status.dart';

/// Generates and downloads guest upload template files (XLSX)
class GuestTemplateGenerator {
  /// Column headers for the guest template
  static const List<String> uploadHeaders = [
    'Name',
    'Email',
    'Max Invite',
    'Address',
    'City',
    'State',
    'Country',
    'Gender',
  ];

  // Export headers (download guest list)
  static const List<String> exportHeaders = [
    'Name',
    'Email',
    'Max Invite',
    'Event Presence',
    'Gender',
    'Invited',
  ];

  static String _invitedLabel(dynamic guest) {
    try {
      final v = (guest as dynamic).isInvited;
      if (v == true) return 'Yes';
      if (v == false) return 'No';
    } catch (_) {}
    return 'No';
  }

  static String _eventPresenceLabel(GuestRsvpStatus? rsvp) {
    if (rsvp == null) return '—';
    if (!rsvp.hasResponded) return 'Pending';
    if (rsvp.isAttending == true) return 'Yes';
    if (rsvp.isAttending == false) return 'No';
    return 'Responded';
  }

  /// Example rows to help users understand the format
  static const List<List<String>> exampleRows = [
    [
      'John Doe',
      'john@example.com',
      '2',
      '123 Main St',
      'New York',
      'NY',
      'USA',
      'male'
    ],
    [
      'Jane Smith',
      'jane@example.com',
      '0',
      '456 Oak Ave',
      'Los Angeles',
      'CA',
      'USA',
      'female'
    ],
    ['Bob Johnson', 'bob@example.com', '1', '', '', '', '', 'preferNotToSay'],
  ];

  /// Downloads an XLSX template file
  ///
  /// Parameters:
  /// - eventName: Name of the event to include in the filename
  /// - includeExamples: If true, includes example rows to guide users
  /// - capacity: Optional event capacity to pre-populate rows (defaults to 3 example rows if not provided)
  static void downloadXlsxTemplate({
    required String eventName,
    bool includeExamples = true,
    int? capacity,
  }) {
    final excel = Excel.createExcel();

    // Create Instructions sheet first
    _createInstructionsSheet(excel);

    // Create Guests sheet
    final Sheet sheet = excel['Guests'];

    // Delete the default Sheet1 that was created
    excel.delete('Sheet1');

    // Add row number header in column 0
    final numberHeaderCell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    numberHeaderCell.value = TextCellValue('#');
    numberHeaderCell.cellStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#D3D3D3'),
      fontColorHex: ExcelColor.fromHexString('#000000'),
    );

    // Add headers (shifted by 1 column to make room for row numbers)
    for (int i = 0; i < uploadHeaders.length; i++) {
      final cell = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i + 1, rowIndex: 0));
      cell.value = TextCellValue(uploadHeaders[i]);

      // Style the header row
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#D3D3D3'),
        fontColorHex: ExcelColor.fromHexString('#000000'),
      );
    }

    // Determine number of rows to add
    int rowsToAdd = 3; // Default to 3 example rows
    if (capacity != null && capacity > 0) {
      rowsToAdd = capacity;
    }

    // Add rows
    if (includeExamples && rowsToAdd <= 3) {
      // Use example rows if capacity is small or not provided
      for (int rowIdx = 0;
          rowIdx < exampleRows.length && rowIdx < rowsToAdd;
          rowIdx++) {
        // Add row number in column 0
        final numberCell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx + 1));
        numberCell.value = IntCellValue(rowIdx + 1);

        // Add data (shifted by 1 column)
        for (int colIdx = 0; colIdx < exampleRows[rowIdx].length; colIdx++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(
              columnIndex: colIdx + 1, rowIndex: rowIdx + 1));
          cell.value = TextCellValue(exampleRows[rowIdx][colIdx]);
        }
      }
    } else {
      // Generate placeholder rows based on capacity
      for (int rowIdx = 0; rowIdx < rowsToAdd; rowIdx++) {
        // Add row number in column 0
        final numberCell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx + 1));
        numberCell.value = IntCellValue(rowIdx + 1);

        // Add first 3 rows as examples, rest as empty for user to fill
        if (rowIdx < 3) {
          for (int colIdx = 0; colIdx < exampleRows[rowIdx].length; colIdx++) {
            final cell = sheet.cell(CellIndex.indexByColumnRow(
                columnIndex: colIdx + 1, rowIndex: rowIdx + 1));
            cell.value = TextCellValue(exampleRows[rowIdx][colIdx]);
          }
        } else {
          // Add empty rows for remaining capacity
          for (int colIdx = 0; colIdx < uploadHeaders.length; colIdx++) {
            final cell = sheet.cell(CellIndex.indexByColumnRow(
                columnIndex: colIdx + 1, rowIndex: rowIdx + 1));
            cell.value = TextCellValue('');
          }
        }
      }
    }

    // Auto-size columns
    // Set row number column width (narrower)
    sheet.setColumnWidth(0, 8);

    // Set data columns width
    for (int i = 0; i < uploadHeaders.length; i++) {
      sheet.setColumnWidth(i + 1, 20);
    }

    final bytes = excel.encode();
    if (bytes != null) {
      // Sanitize event name for filename (remove invalid characters)
      final sanitizedEventName = eventName
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '_')
          .trim();

      _downloadFile(
        bytes: Uint8List.fromList(bytes),
        fileName: '${sanitizedEventName}_guest_upload_template.xlsx',
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    }
  }

  /// Creates an instructions sheet with upload guidelines
  static void _createInstructionsSheet(Excel excel) {
    final sheet = excel['Instructions'];

    // Title
    final titleCell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = TextCellValue('Guest Upload Template - Instructions');
    titleCell.cellStyle = CellStyle(
      bold: true,
      fontSize: 16,
      fontColorHex: ExcelColor.fromHexString('#000000'),
    );

    // Required Fields Section
    var row = 2;
    final requiredTitle =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    requiredTitle.value = TextCellValue('REQUIRED FIELDS:');
    requiredTitle.cellStyle = CellStyle(
      bold: true,
      fontSize: 12,
      fontColorHex: ExcelColor.fromHexString('#FF0000'),
    );

    row++;
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue('• Name - Full name of the guest');

    row++;
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue('• Email - Valid email address');

    // Optional Fields Section
    row += 2;
    final optionalTitle =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    optionalTitle.value = TextCellValue('OPTIONAL FIELDS:');
    optionalTitle.cellStyle = CellStyle(
      bold: true,
      fontSize: 12,
    );

    row++;
    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value =
        TextCellValue(
            '• Max Invite - Number of additional guests this person can bring (0 or more)');

    row++;
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue('• Address - Street address');

    row++;
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue('• City - City name');

    row++;
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue('• State - State or province');

    row++;
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue('• Country - Country name');

    row++;
    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value =
        TextCellValue('• Gender - Values: male, female, preferNotToSay');

    // Upload Instructions
    row += 2;
    final uploadTitle =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    uploadTitle.value = TextCellValue('HOW TO UPLOAD:');
    uploadTitle.cellStyle = CellStyle(
      bold: true,
      fontSize: 12,
    );

    row++;
    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value =
        TextCellValue('1. Fill in guest information in the "Guests" sheet');

    row++;
    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value =
        TextCellValue('2. Go to File → Save As → CSV (Comma delimited)');

    row++;
    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value =
        TextCellValue(
            '3. Make sure to select the "Guests" sheet before exporting');

    row++;
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue('4. Upload the CSV file to the system');

    // Important Notes
    row += 2;
    final notesTitle =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    notesTitle.value = TextCellValue('IMPORTANT NOTES:');
    notesTitle.cellStyle = CellStyle(
      bold: true,
      fontSize: 12,
      fontColorHex: ExcelColor.fromHexString('#FF0000'),
    );

    row++;
    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value =
        TextCellValue(
            '• Only Name and Email are required - other fields are optional');

    row++;
    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value =
        TextCellValue('• Duplicate emails will be skipped during upload');

    row++;
    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value =
        TextCellValue(
            '• You can delete the row number (#) column before exporting');

    row++;
    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value =
        TextCellValue(
            '• This instructions sheet will NOT be included in CSV export');

    // Set column width for readability
    sheet.setColumnWidth(0, 60);
  }

  /// Downloads an XLSX file with current guest list data using controller
  ///
  /// Parameters:
  /// - eventName: Name of the event to include in the filename
  /// - controller: AdminGuestListController to get guest data from
  static void downloadGuestList({
    required String eventName,
    required AdminGuestListController controller,
  }) {
    downloadGuestListFromData(
      eventName: eventName,
      guests: controller.guests,
      rsvpByGuestId:
          Map<String, GuestRsvpStatus>.from(controller.rsvpByGuestId),
    );
  }

  /// Downloads an XLSX file with current guest list data
  ///
  /// Parameters:
  /// - eventName: Name of the event to include in the filename
  /// - guests: List of GuestModel objects to export
  static void downloadGuestListFromData({
    required String eventName,
    required List<dynamic> guests,
    Map<String, GuestRsvpStatus>? rsvpByGuestId, // ✅ NEW
  }) {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Guests'];
    excel.delete('Sheet1');

    // Row number header
    final numberHeaderCell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    numberHeaderCell.value = TextCellValue('#');
    numberHeaderCell.cellStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#D3D3D3'),
      fontColorHex: ExcelColor.fromHexString('#000000'),
    );

    // ✅ Export headers (includes Event Presence)
    for (int i = 0; i < exportHeaders.length; i++) {
      final cell = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i + 1, rowIndex: 0));
      cell.value = TextCellValue(exportHeaders[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#D3D3D3'),
        fontColorHex: ExcelColor.fromHexString('#000000'),
      );
    }

    String getGenderName(dynamic gender) {
      if (gender == null) return '';
      if (gender is String) return gender;
      try {
        return (gender as dynamic).name as String? ?? '';
      } catch (_) {
        return gender.toString();
      }
    }

    for (int rowIdx = 0; rowIdx < guests.length; rowIdx++) {
      final guest = guests[rowIdx];

      // Row number
      sheet
          .cell(
              CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx + 1))
          .value = IntCellValue(rowIdx + 1);

      final gid = (guest.guestId ?? '').toString();
      final presence = _eventPresenceLabel(rsvpByGuestId?[gid]);

      final guestData = [
        (guest.name ?? '').toString(),
        (guest.email ?? '').toString(),
        (guest.maxGuestInvite ?? 0).toString(),
        presence,
        getGenderName(guest.gender),
        _invitedLabel(guest), // ✅ Yes/No
      ];

      for (int colIdx = 0; colIdx < guestData.length; colIdx++) {
        sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: colIdx + 1, rowIndex: rowIdx + 1))
            .value = TextCellValue(guestData[colIdx]);
      }
    }

    sheet.setColumnWidth(0, 8);
    for (int i = 0; i < exportHeaders.length; i++) {
      sheet.setColumnWidth(i + 1, 20);
    }

    final bytes = excel.encode();
    if (bytes != null) {
      final sanitizedEventName = eventName
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '_')
          .trim();

      _downloadFile(
        bytes: Uint8List.fromList(bytes),
        fileName: 'event_name_${sanitizedEventName}_guest_list.xlsx',
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    }
  }

  /// Helper method to trigger file download in web browser
  static void _downloadFile({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) {
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
