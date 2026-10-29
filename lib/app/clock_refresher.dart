import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';

/// Calculates the duration from [now] until 1 second past the next local midnight.
///
/// Uses calendar year/month/day math to account for Daylight Saving Time changes
/// rather than assuming a fixed 24-hour day.
Duration timeUntilNextMidnight(DateTime now) {
  final nextMidnight = DateTime(now.year, now.month, now.day + 1);
  final target = nextMidnight.add(const Duration(seconds: 1));
  final diff = target.difference(now);
  return diff.isNegative ? const Duration(seconds: 1) : diff;
}

/// A wrapper widget that observes app lifecycle and midnight transitions,
/// invalidating [clockProvider] whenever the calendar date advances.
class ClockRefresher extends ConsumerStatefulWidget {
  final Widget child;
  final DateTime Function()? now;

  const ClockRefresher({
    super.key,
    required this.child,
    this.now,
  });

  @override
  ConsumerState<ClockRefresher> createState() => _ClockRefresherState();
}

class _ClockRefresherState extends ConsumerState<ClockRefresher>
    with WidgetsBindingObserver {
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnightTimer();
  }

  DateTime _getNow() => widget.now != null ? widget.now!() : DateTime.now();

  void _scheduleMidnightTimer() {
    _midnightTimer?.cancel();
    final now = _getNow();
    final duration = timeUntilNextMidnight(now);
    _midnightTimer = Timer(duration, () {
      if (!mounted) return;
      ref.invalidate(clockProvider);
      _scheduleMidnightTimer();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final currentClock = ref.read(clockProvider);
      final nowDate = _getNow();
      if (currentClock.year != nowDate.year ||
          currentClock.month != nowDate.month ||
          currentClock.day != nowDate.day) {
        ref.invalidate(clockProvider);
        _scheduleMidnightTimer();
      }
    }
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
