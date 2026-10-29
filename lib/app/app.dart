import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../core/strings.dart';
import '../data/db/app_database.dart';
import '../data/providers.dart';
import '../features/children/add_child_screen.dart';
import '../features/home/home_screen.dart';
import '../features/setup/disclaimer_screen.dart';
import '../services/temp_file_cleanup.dart';
import 'clock_refresher.dart';
import 'theme.dart';

/// Root widget configuring the MaterialApp, themes, and initial navigation.
class HomeledgerApp extends StatelessWidget {
  final Widget? home;

  const HomeledgerApp({
    super.key,
    this.home,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        overscroll: false,
        physics: const ClampingScrollPhysics(),
      ),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        // Protect layout and button text on phones with aggressive display scaling (e.g. Samsung One UI)
        // by clamping the textScaler to a comfortable, accessible range [0.85, 1.25].
        final clampedScaler = mediaQuery.textScaler.clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.25,
        );
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: clampedScaler),
          child: ClockRefresher(child: child ?? const SizedBox()),
        );
      },
      home: home ?? const AppStartupGate(),
    );
  }
}

/// Startup gate determining whether to show Disclaimer, Add Child, or Home.
class AppStartupGate extends ConsumerStatefulWidget {
  const AppStartupGate({super.key});

  @override
  ConsumerState<AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends ConsumerState<AppStartupGate> {
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeApp();
  }

  Future<void> _initializeApp() async {
    final subjectRepo = ref.read(subjectRepositoryProvider);
    final settingsRepo = ref.read(settingsRepositoryProvider);
    await subjectRepo.ensureDefaultSubjectsSeeded(settingsRepo);

    // Run orphan cleanup and old temp files cleanup in background on app start without blocking startup
    Future.microtask(() async {
      try {
        await ref.read(sampleStorageServiceProvider).runOrphanCleanup();
      } catch (_) {
        // Background cleanup should never crash or interrupt startup
      }
      try {
        final tempDir = await getTemporaryDirectory();
        final now = ref.read(clockProvider);
        await cleanupOldTempFiles(tempDir, now: now);
      } catch (_) {
        // Background cleanup should never crash or interrupt startup
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, initSnapshot) {
        if (initSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final settingsRepo = ref.watch(settingsRepositoryProvider);
        final childRepo = ref.watch(childRepositoryProvider);

        return FutureBuilder<bool>(
          future: settingsRepo.isDisclaimerAccepted(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final isAccepted = snapshot.data ?? false;
        if (!isAccepted) {
          return const DisclaimerScreen();
        }

        return FutureBuilder<List<Child>>(
          future: childRepo.getAll(),
          builder: (context, childSnapshot) {
            if (childSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final children = childSnapshot.data ?? [];
            if (children.isEmpty) {
              return const AddChildScreen(isFirstChild: true);
            }

            return const HomeScreen();
          },
        );
      },
    );
  },
);
}
}



