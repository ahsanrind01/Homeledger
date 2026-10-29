import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/services/sample_capture_service.dart';

class FakeDocumentScannerClient implements DocumentScannerClient {
  final Future<Uint8List?> Function() onScan;
  int callCount = 0;

  FakeDocumentScannerClient(this.onScan);

  @override
  Future<Uint8List?> scanDocument() {
    callCount++;
    return onScan();
  }
}

class FakeImagePickerClient implements ImagePickerClient {
  final Future<Uint8List?> Function() onPickCamera;
  final Future<Uint8List?> Function() onPickGallery;
  int cameraCallCount = 0;
  int galleryCallCount = 0;

  FakeImagePickerClient({
    required this.onPickCamera,
    required this.onPickGallery,
  });

  @override
  Future<Uint8List?> pickFromCamera() {
    cameraCallCount++;
    return onPickCamera();
  }

  @override
  Future<Uint8List?> pickFromGallery() {
    galleryCallCount++;
    return onPickGallery();
  }
}

void main() {
  final sampleBytes = Uint8List.fromList([10, 20, 30, 40]);

  group('SampleCaptureService Fallback Logic', () {
    test('Uses Document Scanner when available and successful', () async {
      final scanner = FakeDocumentScannerClient(() async => sampleBytes);
      final picker = FakeImagePickerClient(
        onPickCamera: () async => throw Exception('Camera should not be called'),
        onPickGallery: () async => throw Exception('Gallery should not be called'),
      );

      final service = SampleCaptureService(
        scannerClient: scanner,
        pickerClient: picker,
      );

      final result = await service.capture();

      expect(result, isNotNull);
      expect(result!.method, CaptureMethod.documentScanner);
      expect(result.bytes, sampleBytes);
      expect(scanner.callCount, 1);
      expect(picker.cameraCallCount, 0);
      expect(picker.galleryCallCount, 0);
    });

    test('User cancels Document Scanner -> returns null without falling back to camera', () async {
      final scanner = FakeDocumentScannerClient(() async => null);
      final picker = FakeImagePickerClient(
        onPickCamera: () async => throw Exception('Camera should not be called'),
        onPickGallery: () async => throw Exception('Gallery should not be called'),
      );

      final service = SampleCaptureService(
        scannerClient: scanner,
        pickerClient: picker,
      );

      final result = await service.capture();

      expect(result, isNull);
      expect(scanner.callCount, 1);
      expect(picker.cameraCallCount, 0);
      expect(picker.galleryCallCount, 0);
    });

    test('Falls back to Camera when Document Scanner throws (e.g. Play services missing)', () async {
      final scanner = FakeDocumentScannerClient(() async => throw Exception('ML Kit unavailable'));
      final picker = FakeImagePickerClient(
        onPickCamera: () async => sampleBytes,
        onPickGallery: () async => throw Exception('Gallery should not be called'),
      );

      final service = SampleCaptureService(
        scannerClient: scanner,
        pickerClient: picker,
      );

      final result = await service.capture();

      expect(result, isNotNull);
      expect(result!.method, CaptureMethod.camera);
      expect(result.bytes, sampleBytes);
      expect(scanner.callCount, 1);
      expect(picker.cameraCallCount, 1);
      expect(picker.galleryCallCount, 0);
    });

    test('User cancels Camera -> returns null without falling back to gallery', () async {
      final scanner = FakeDocumentScannerClient(() async => throw Exception('ML Kit unavailable'));
      final picker = FakeImagePickerClient(
        onPickCamera: () async => null,
        onPickGallery: () async => throw Exception('Gallery should not be called'),
      );

      final service = SampleCaptureService(
        scannerClient: scanner,
        pickerClient: picker,
      );

      final result = await service.capture();

      expect(result, isNull);
      expect(scanner.callCount, 1);
      expect(picker.cameraCallCount, 1);
      expect(picker.galleryCallCount, 0);
    });

    test('Falls back to Gallery when Document Scanner AND Camera both throw', () async {
      final scanner = FakeDocumentScannerClient(() async => throw Exception('ML Kit unavailable'));
      final picker = FakeImagePickerClient(
        onPickCamera: () async => throw Exception('Camera hardware error'),
        onPickGallery: () async => sampleBytes,
      );

      final service = SampleCaptureService(
        scannerClient: scanner,
        pickerClient: picker,
      );

      final result = await service.capture();

      expect(result, isNotNull);
      expect(result!.method, CaptureMethod.gallery);
      expect(result.bytes, sampleBytes);
      expect(scanner.callCount, 1);
      expect(picker.cameraCallCount, 1);
      expect(picker.galleryCallCount, 1);
    });

    test('Returns null when all capture methods throw', () async {
      final scanner = FakeDocumentScannerClient(() async => throw Exception('ML Kit unavailable'));
      final picker = FakeImagePickerClient(
        onPickCamera: () async => throw Exception('Camera error'),
        onPickGallery: () async => throw Exception('Gallery error'),
      );

      final service = SampleCaptureService(
        scannerClient: scanner,
        pickerClient: picker,
      );

      final result = await service.capture();

      expect(result, isNull);
      expect(scanner.callCount, 1);
      expect(picker.cameraCallCount, 1);
      expect(picker.galleryCallCount, 1);
    });
  });
}
