import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/db/app_database.dart';
import 'package:homeledger/data/providers.dart';
import 'package:homeledger/data/repositories/child_repository.dart';
import 'package:homeledger/data/repositories/sample_repository.dart';
import 'package:homeledger/data/repositories/subject_repository.dart';
import 'package:homeledger/domain/feature_policy.dart';
import 'package:homeledger/features/home/home_screen.dart';
import 'package:homeledger/features/samples/sample_capture_screen.dart';
import 'package:homeledger/features/samples/sample_library_screen.dart';
import 'package:homeledger/features/samples/sample_viewer_screen.dart';
import 'package:homeledger/services/sample_capture_service.dart';
import 'package:homeledger/services/sample_storage_service.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

class FakeCaptureClient implements DocumentScannerClient, ImagePickerClient {
  Uint8List? sampleResult;
  FakeCaptureClient({this.sampleResult});

  @override
  Future<Uint8List?> scanDocument() async => sampleResult;

  @override
  Future<Uint8List?> pickFromCamera() async => sampleResult;

  @override
  Future<Uint8List?> pickFromGallery() async => sampleResult;
}

void main() {
  late AppDatabase db;
  late ChildRepository childRepo;
  late SubjectRepository subjectRepo;
  late SampleRepository sampleRepo;
  late Directory tempDocsDir;
  late SampleStorageService storageService;
  late int testChildId;
  late int mathSubjectId;
  late int scienceSubjectId;

  final fixedClock = DateTime(2026, 10, 19, 10, 0);

  Uint8List createTestJpeg() {
    final image = img.Image(width: 50, height: 50);
    img.fill(image, color: img.ColorRgb8(100, 200, 100));
    return Uint8List.fromList(img.encodeJpg(image));
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    childRepo = ChildRepository(db);
    subjectRepo = SubjectRepository(db);
    sampleRepo = SampleRepository(db);

    tempDocsDir = await Directory.systemTemp.createTemp('homeledger_widget_test_');

    storageService = SampleStorageService(
      sampleRepository: sampleRepo,
      getDocumentsDirectory: () async => tempDocsDir,
      imageProcessor: (bytes) async => bytes,
    );

    testChildId = await childRepo.add(
      const ChildrenCompanion(
        name: drift.Value('Emma'),
        ruleId: drift.Value('mo_standard'),
        schoolYearStart: drift.Value('2026-07-01'),
        schoolYearEnd: drift.Value('2027-06-30'),
        createdAt: drift.Value(1000),
      ),
    );

    mathSubjectId = await subjectRepo.add(
      const SubjectsCompanion(
        name: drift.Value('Math'),
        isCore: drift.Value(true),
        sortOrder: drift.Value(1),
      ),
    );

    scienceSubjectId = await subjectRepo.add(
      const SubjectsCompanion(
        name: drift.Value('Science'),
        isCore: drift.Value(true),
        sortOrder: drift.Value(2),
      ),
    );
  });

  tearDown(() async {
    await db.close();
    if (await tempDocsDir.exists()) {
      await tempDocsDir.delete(recursive: true);
    }
  });

  Widget buildTestApp({
    required Widget child,
    SampleCaptureService? captureService,
    FeatureAccess? scanAccess,
  }) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        childRepositoryProvider.overrideWithValue(childRepo),
        subjectRepositoryProvider.overrideWithValue(subjectRepo),
        sampleRepositoryProvider.overrideWithValue(sampleRepo),
        sampleStorageServiceProvider.overrideWithValue(storageService),
        if (captureService != null)
          sampleCaptureServiceProvider.overrideWithValue(captureService),
        clockProvider.overrideWithValue(fixedClock),
        featureAccessProvider(Feature.scanSample).overrideWithValue(
          scanAccess ?? FeatureAccess.allowed,
        ),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  Future<void> flushTest(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  }

  group('SampleLibraryScreen', () {
    testWidgets('Renders empty state when child has no work samples', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: SampleLibraryScreen(childId: testChildId),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No work samples yet'), findsOneWidget);
      expect(find.byKey(const ValueKey('library_empty_scan_button')), findsOneWidget);

      await flushTest(tester);
    });

    testWidgets('Renders thumbnails sorted newest first', (tester) async {
      await tester.runAsync(() async {
        await storageService.saveSample(
          childId: testChildId,
          rawBytes: createTestJpeg(),
          day: '2026-10-10',
          title: 'Older sample',
        );

        await storageService.saveSample(
          childId: testChildId,
          rawBytes: createTestJpeg(),
          day: '2026-10-19',
          title: 'Newer sample',
        );
      });

      await tester.pumpWidget(
        buildTestApp(
          child: SampleLibraryScreen(childId: testChildId),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Newer sample'), findsOneWidget);
      expect(find.text('Older sample'), findsOneWidget);

      final newerPos = tester.getTopLeft(find.text('Newer sample'));
      final olderPos = tester.getTopLeft(find.text('Older sample'));
      expect(newerPos.dy <= olderPos.dy, isTrue);

      await flushTest(tester);
    });

    testWidgets('Subject filter filters samples correctly', (tester) async {
      await tester.runAsync(() async {
        await storageService.saveSample(
          childId: testChildId,
          rawBytes: createTestJpeg(),
          day: '2026-10-18',
          subjectId: mathSubjectId,
          title: 'Math sample',
        );

        await storageService.saveSample(
          childId: testChildId,
          rawBytes: createTestJpeg(),
          day: '2026-10-19',
          subjectId: scienceSubjectId,
          title: 'Science sample',
        );
      });

      await tester.pumpWidget(
        buildTestApp(
          child: SampleLibraryScreen(childId: testChildId),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Math sample'), findsOneWidget);
      expect(find.text('Science sample'), findsOneWidget);

      // Tap on Math filter chip
      await tester.tap(find.byKey(ValueKey('filter_subject_$mathSubjectId')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Math sample'), findsOneWidget);
      expect(find.text('Science sample'), findsNothing);

      // Tap on All filter chip
      await tester.tap(find.byKey(const ValueKey('filter_subject_all')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Math sample'), findsOneWidget);
      expect(find.text('Science sample'), findsOneWidget);

      await flushTest(tester);
    });

    testWidgets('Missing file displays "File missing" placeholder card', (tester) async {
      late WorkSample sample;
      await tester.runAsync(() async {
        sample = await storageService.saveSample(
          childId: testChildId,
          rawBytes: createTestJpeg(),
          day: '2026-10-19',
          title: 'Corrupted sample',
        );

        final file = File(p.join(tempDocsDir.path, sample.filePath));
        await file.delete();
      });

      await tester.pumpWidget(
        buildTestApp(
          child: SampleLibraryScreen(childId: testChildId),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Corrupted sample'), findsOneWidget);
      expect(find.text('File missing'), findsOneWidget);

      await flushTest(tester);
    });

    testWidgets('Cancel from the scanner fake: returns quietly, no row added, no file in samples/', (tester) async {
      final fakeCapture = FakeCaptureClient(sampleResult: null);
      final captureService = SampleCaptureService(
        scannerClient: fakeCapture,
        pickerClient: fakeCapture,
      );

      await tester.pumpWidget(
        buildTestApp(
          child: SampleLibraryScreen(childId: testChildId),
          captureService: captureService,
        ),
      );
      await tester.pumpAndSettle();

      // Tap empty state scan button
      await tester.tap(find.byKey(const ValueKey('library_empty_scan_button')));
      await tester.pumpAndSettle();

      // Verify no navigation to SampleCaptureScreen occurred
      expect(find.byType(SampleCaptureScreen), findsNothing);
      expect(find.byType(SampleLibraryScreen), findsOneWidget);

      // Verify no error message/snackbar
      expect(find.byType(SnackBar), findsNothing);

      // Verify no row in database
      final samples = await sampleRepo.listForChild(testChildId);
      expect(samples, isEmpty);

      // Verify no file in samples folder
      final samplesDir = Directory(p.join(tempDocsDir.path, 'samples'));
      if (samplesDir.existsSync()) {
        expect(samplesDir.listSync(), isEmpty);
      }

      await flushTest(tester);
    });

    testWidgets('Grid thumbnail has cacheWidth set', (tester) async {
      await tester.runAsync(() async {
        await storageService.saveSample(
          childId: testChildId,
          rawBytes: createTestJpeg(),
          day: '2026-10-19',
          title: 'Thumbnail test',
        );
      });

      await tester.pumpWidget(
        buildTestApp(
          child: SampleLibraryScreen(childId: testChildId),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final imageWidget = tester.widget<Image>(imageFinder);
      expect(imageWidget.image, isA<ResizeImage>());
      final resizeImage = imageWidget.image as ResizeImage;
      expect(resizeImage.width, isNotNull);
      expect(resizeImage.width! > 0, isTrue);

      await flushTest(tester);
    });
  });

  group('SampleCaptureScreen', () {
    testWidgets('Shows capture badge, image preview, and saves successfully', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final testBytes = createTestJpeg();
      final captureResult = CaptureResult(
        bytes: testBytes,
        method: CaptureMethod.documentScanner,
      );

      await tester.pumpWidget(
        buildTestApp(
          child: SampleCaptureScreen(
            childId: testChildId,
            captureResult: captureResult,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Badge
      expect(find.text('Captured via Document scanner'), findsWidgets);

      // Enter title
      await tester.enterText(
        find.byKey(const ValueKey('sample_title_field')),
        'Botany drawing',
      );
      await tester.pump();

      // Ensure button is visible in scrollview and tap Save
      await tester.ensureVisible(find.byKey(const ValueKey('sample_save_button')));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('sample_save_button')));
      await tester.pump();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify row was saved in DB
      final samples = await sampleRepo.listForChild(testChildId);
      expect(samples.length, 1);
      expect(samples.first.title, 'Botany drawing');
      expect(samples.first.day, '2026-10-19');

      await flushTest(tester);
    });
  });

  group('SampleViewerScreen', () {
    testWidgets('Renders interactive viewer with pinch zoom and deletes with confirm dialog', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late WorkSample sample;
      await tester.runAsync(() async {
        sample = await storageService.saveSample(
          childId: testChildId,
          rawBytes: createTestJpeg(),
          day: '2026-10-19',
          subjectId: mathSubjectId,
          title: 'Fractions quiz',
        );
      });

      await tester.pumpWidget(
        buildTestApp(
          child: SampleViewerScreen(sampleId: sample.id),
        ),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Fractions quiz'), findsWidgets);
      expect(find.text('Math'), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      final viewerImage = tester.widget<Image>(find.byType(Image));
      expect(viewerImage.image, isA<ResizeImage>());
      expect((viewerImage.image as ResizeImage).width, equals(2048));

      // Tap delete button in AppBar
      await tester.tap(find.byKey(const ValueKey('sample_viewer_delete_button')));
      await tester.pump(const Duration(milliseconds: 300));

      // Confirm dialog appears
      expect(find.text('Delete work sample?'), findsOneWidget);

      // Tap Delete in dialog
      await tester.tap(find.text('Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();

      // Sample should be deleted from DB and disk
      expect(await sampleRepo.getById(sample.id), isNull);
      final file = File(p.join(tempDocsDir.path, sample.filePath));
      expect(file.existsSync(), isFalse);

      await flushTest(tester);
    });

    testWidgets('Missing file displays "File missing from device" message in viewer', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late WorkSample sample;
      await tester.runAsync(() async {
        sample = await storageService.saveSample(
          childId: testChildId,
          rawBytes: createTestJpeg(),
          day: '2026-10-19',
          title: 'Missing image sample',
        );

        final file = File(p.join(tempDocsDir.path, sample.filePath));
        await file.delete();
      });

      await tester.pumpWidget(
        buildTestApp(
          child: SampleViewerScreen(sampleId: sample.id),
        ),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('File missing from device'), findsOneWidget);

      await flushTest(tester);
    });
  });

  group('HomeScreen to Samples integration', () {
    testWidgets('Tapping Samples shortcut on HomeScreen opens SampleLibraryScreen', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final shortcutFinder = find.byKey(const ValueKey('shortcut_samples'));
      expect(shortcutFinder, findsOneWidget);

      await tester.ensureVisible(shortcutFinder);
      await tester.tap(shortcutFinder);
      await tester.pumpAndSettle();

      expect(find.byType(SampleLibraryScreen), findsOneWidget);
      expect(find.text('Work samples'), findsOneWidget);

      await flushTest(tester);
    });
  });
}
