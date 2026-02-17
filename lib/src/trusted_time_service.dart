import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'native_uptime.dart';

/// A tamper-resistant trusted time service.
///
/// This service:
/// - Fetches UTC time from a trusted HTTPS source
/// - Anchors it to native monotonic uptime (via FFI)
/// - Calculates current time using uptime delta
/// - Does NOT rely on device clock or timezone
///
/// Recommended usage:
/// ```dart
/// await TrustedTimeService().initialize();
/// final now = TrustedTimeService().now();
/// ```
class TrustedTimeService {
  TrustedTimeService._internal();

  static final TrustedTimeService _instance = TrustedTimeService._internal();

  /// Singleton factory
  factory TrustedTimeService() => _instance;

  final UptimeFFI _uptime = UptimeFFI();

  /// HTTPS trusted time provider (UTC)
  static const String _trustedTimeUrl =
      'https://timeapi.io/api/Time/current/zone?timeZone=UTC';

  DateTime? _anchorUtc;
  int? _anchorUptimeMillis;

  int _defaultOffsetHours = 0;
  int _defaultOffsetMinutes = 0;

  /// Whether the service has been initialized successfully.
  bool get isInitialized => _anchorUtc != null && _anchorUptimeMillis != null;

  /// Initializes the trusted time service.
  ///
  /// - Fetches trusted UTC from HTTPS
  /// - Anchors it with monotonic uptime
  /// - Optionally sets default timezone offset
  ///
  /// Throws [Exception] if initialization fails.
  Future<void> initialize({
    int? defaultOffsetHours,
    int? defaultOffsetMinutes,
    Duration timeout = const Duration(seconds: 5),
    DateTime? trustedAnchorUtc,
  }) async {
    if (defaultOffsetHours != null) {
      _defaultOffsetHours = defaultOffsetHours;
    }
    if (defaultOffsetMinutes != null) {
      _defaultOffsetMinutes = defaultOffsetMinutes;
    }

    // Manual anchor injection (for testing or server-provided time)
    if (trustedAnchorUtc != null) {
      _anchorUtc = trustedAnchorUtc.toUtc();
      _anchorUptimeMillis = _uptime.getUptimeMillis();
      return;
    }

    final stopwatch = Stopwatch()..start();

    try {
      final response = await http
          .get(Uri.parse(_trustedTimeUrl))
          .timeout(timeout);

      if (response.statusCode != HttpStatus.ok) {
        throw Exception(
          'Trusted time server responded with ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body);
      final datetimeStr = data['dateTime'] as String;

      // Parse as UTC
      final serverUtc = DateTime.parse(datetimeStr);

      stopwatch.stop();

      // Approximate network latency compensation (RTT / 2)
      final latencyCompensation = Duration(
        milliseconds: stopwatch.elapsedMilliseconds ~/ 2,
      );

      _anchorUtc = serverUtc.add(latencyCompensation);
      _anchorUptimeMillis = _uptime.getUptimeMillis();
    } catch (e) {
      stopwatch.stop();
      throw Exception('Failed to initialize trusted time: $e');
    }
  }

  /// Returns current trusted UTC time.
  ///
  /// Uses:
  /// `anchorUtc + (currentUptime - anchorUptime)`
  ///
  /// Throws if service is not initialized.
  DateTime nowUtc() {
    if (!isInitialized) {
      throw StateError(
        'TrustedTimeService not initialized. Call initialize() first.',
      );
    }

    final deltaMillis = _uptime.getUptimeMillis() - _anchorUptimeMillis!;

    return _anchorUtc!.add(Duration(milliseconds: deltaMillis));
  }

  /// Returns trusted time adjusted by offset.
  ///
  /// This does NOT rely on device timezone.
  /// Offset must be explicitly provided or pre-configured.
  DateTime now({int? offsetHours, int? offsetMinutes}) {
    final utc = nowUtc();

    return utc.add(
      Duration(
        hours: offsetHours ?? _defaultOffsetHours,
        minutes: offsetMinutes ?? _defaultOffsetMinutes,
      ),
    );
  }

  /// Clears anchor (forces reinitialization).
  void reset() {
    _anchorUtc = null;
    _anchorUptimeMillis = null;
  }
}
