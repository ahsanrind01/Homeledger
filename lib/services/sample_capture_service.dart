import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:image_picker/image_picker.dart';

/// The method used to capture the image.
enum CaptureMethod {
  documentScanner('Document scanner'),
  camera('Camera'),
  gallery('Photo gallery');

  final String displayName;
  const CaptureMethod(this.displayName);
}

/// The result of capturing a work sample, including the raw bytes and source method.
class CaptureResult {
  final Uint8List bytes;
  final CaptureMethod method;

  const CaptureResult({
    required this.bytes,
    required this.method,
  });
}

/// Interface for document scanner operations.
abstract class DocumentScannerClient {
  Future<Uint8List?> scanDocument();
}

/// Interface for camera and gallery picking operations.
abstract class ImagePickerClient {
  Future<Uint8List?> pickFromCamera();
  Future<Uint8List?> pickFromGallery();
}

/// Production implementation of DocumentScannerClient using Google ML Kit.
class MlKitDocumentScannerClient implements DocumentScannerClient {
  @override
  Future<Uint8List?> scanDocument() async {
    final scanner = DocumentScanner(
      options: DocumentScannerOptions(
        documentFormats: const {DocumentFormat.jpeg},
        mode: ScannerMode.full,
        pageLimit: 1,
        isGalleryImport: false,
      ),
    );

    try {
      final result = await scanner.scanDocument();
      final images = result.images;
      if (images != null && images.isNotEmpty) {
        final file = File(images.first);
        final bytes = await file.readAsBytes();
        try {
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
        return bytes;
      }
      return null;
    } finally {
      await scanner.close();
    }
  }
}

/// Production implementation of ImagePickerClient using the image_picker plugin.
class ImagePickerClientImpl implements ImagePickerClient {
  final ImagePicker _picker;

  ImagePickerClientImpl({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  @override
  Future<Uint8List?> pickFromCamera() async {
    final xFile = await _picker.pickImage(source: ImageSource.camera);
    if (xFile != null) {
      return await xFile.readAsBytes();
    }
    return null;
  }

  @override
  Future<Uint8List?> pickFromGallery() async {
    final xFile = await _picker.pickImage(source: ImageSource.gallery);
    if (xFile != null) {
      return await xFile.readAsBytes();
    }
    return null;
  }
}

/// Service that coordinates capturing work samples with automatic graceful fallback:
/// 1. Tries Google ML Kit Document Scanner.
/// 2. If the scanner throws (e.g. no Google Play services or unsupported device), falls back to Camera.
/// 3. If the Camera throws or is unavailable, falls back to Gallery.
class SampleCaptureService {
  final DocumentScannerClient _scannerClient;
  final ImagePickerClient _pickerClient;

  SampleCaptureService({
    DocumentScannerClient? scannerClient,
    ImagePickerClient? pickerClient,
  })  : _scannerClient = scannerClient ?? MlKitDocumentScannerClient(),
        _pickerClient = pickerClient ?? ImagePickerClientImpl();

  Future<CaptureResult?> capture() async {
    // 1. Try Document Scanner
    try {
      final bytes = await _scannerClient.scanDocument();
      if (bytes != null) {
        return CaptureResult(
          bytes: bytes,
          method: CaptureMethod.documentScanner,
        );
      }
      // User cancelled scanner without error
      return null;
    } catch (_) {
      // Document scanner unavailable or threw an error -> fall back to Camera
    }

    // 2. Fall back to Camera
    try {
      final bytes = await _pickerClient.pickFromCamera();
      if (bytes != null) {
        return CaptureResult(
          bytes: bytes,
          method: CaptureMethod.camera,
        );
      }
      // User cancelled camera without error
      return null;
    } catch (_) {
      // Camera unavailable or threw an error -> fall back to Gallery
    }

    // 3. Fall back to Gallery
    try {
      final bytes = await _pickerClient.pickFromGallery();
      if (bytes != null) {
        return CaptureResult(
          bytes: bytes,
          method: CaptureMethod.gallery,
        );
      }
      return null;
    } catch (_) {
      // All fallback attempts failed
      return null;
    }
  }
}
