import 'package:file_picker/file_picker.dart';
import 'package:traxx_wepapp/models/guest.dart';

/// Parses a file (CSV, XLSX) and returns a list of Guest objects.
abstract class FileParser {
  List<Guest> parseFile(PlatformFile file);
}
