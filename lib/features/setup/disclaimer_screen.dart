import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/strings.dart';
import '../../data/providers.dart';
import '../children/add_child_screen.dart';
import '../home/home_screen.dart';

/// One-time legal disclaimer screen shown on first launch.
class DisclaimerScreen extends ConsumerWidget {
  final VoidCallback? onAccepted;

  const DisclaimerScreen({
    super.key,
    this.onAccepted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.appName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      AppStrings.fullDisclaimer,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: () async {
                      await ref
                          .read(settingsRepositoryProvider)
                          .setDisclaimerAccepted(true);

                      if (context.mounted) {
                        if (onAccepted != null) {
                          onAccepted!();
                        } else {
                          final children = await ref
                              .read(childRepositoryProvider)
                              .getAll();
                          if (context.mounted) {
                            if (children.isEmpty) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute<void>(
                                  builder: (_) => const AddChildScreen(
                                    isFirstChild: true,
                                  ),
                                ),
                              );
                            } else {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute<void>(
                                  builder: (_) => const HomeScreen(),
                                ),
                              );
                            }
                          }
                        }
                      }
                    },
                    child: const Text('I understand'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
