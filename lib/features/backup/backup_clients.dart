import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

/// Result status of opening the system share sheet for backup files.
enum BackupShareResult {
  success,
  dismissed,
  unavailable,
}

/// Abstraction for opening the system share sheet with a backup zip file.
abstract class BackupShareClient {
  Future<BackupShareResult> shareZip(String filePath, String subject);
}

/// Standard Android share sheet client using `share_plus`.
class SharePlusBackupShareClient implements BackupShareClient {
  @override
  Future<BackupShareResult> shareZip(String filePath, String subject) async {
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath, mimeType: 'application/zip')],
        subject: subject,
      ),
    );
    switch (result.status) {
      case ShareResultStatus.success:
        return BackupShareResult.success;
      case ShareResultStatus.dismissed:
        return BackupShareResult.dismissed;
      case ShareResultStatus.unavailable:
        return BackupShareResult.unavailable;
    }
  }
}


/// Abstraction for choosing a zip file from device storage or Google Drive.
abstract class FilePickerClient {
  Future<String?> pickZipFile();
}

/// System document picker client using `file_picker` (Android Storage Access Framework).
class SystemFilePickerClient implements FilePickerClient {
  @override
  Future<String?> pickZipFile() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (files.isNotEmpty) {
      return files.first.path;
    }
    return null;
  }
}
