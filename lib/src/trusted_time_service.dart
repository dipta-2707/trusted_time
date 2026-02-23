import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:http/http.dart' as http;

import 'native_uptime.dart';

/// A tamper-resistant trusted time service.
///
/// This service provides a **secure and reliable time source**
/// that does not depend on the device system clock, which can be
/// modified by users or malicious apps.
///
/// ## Recommended usage
/// ```dart
/// await TrustedTimeService().initialize();
/// final now = TrustedTimeService().now();
/// ```
class TrustedTimeService {
  TrustedTimeService._internal();

  static final TrustedTimeService _instance = TrustedTimeService._internal();

  /// Returns the singleton instance of [TrustedTimeService].
  ///
  /// This ensures that the same trusted anchor and uptime reference
  /// are used throughout the entire app lifecycle.
  factory TrustedTimeService() => _instance;

  final UptimeFFI _uptime = UptimeFFI();

  /// HTTPS endpoint used to fetch trusted UTC time.
  static const String _trustedTimeUrl = 'https://time.shafi.dev/?timeZone=UTC';

  DateTime? _anchorUtc;
  int? _anchorUptimeMillis;

  int _defaultOffsetHours = 0;
  int _defaultOffsetMinutes = 0;

  /// Returns whether the service has been initialized successfully.
  ///
  /// The service is considered initialized when:
  /// - Trusted UTC time has been fetched.
  /// - Native uptime has been anchored.
  ///
  /// If `false`, calls to [now] and [nowUtc] will fallback to system time.
  bool get isInitialized => _anchorUtc != null && _anchorUptimeMillis != null;

  /// Initializes the trusted time service.
  ///
  /// This method must be called **once at app startup** before
  /// accessing trusted time.
  ///
  /// ## Parameters
  /// - [defaultOffsetHours]: Default timezone hour offset applied to [now].
  /// - [defaultOffsetMinutes]: Default timezone minute offset.
  /// - [timeout]: Maximum time to wait for the trusted server.
  /// - [trustedAnchorUtc]: Optional manual time anchor.
  ///
  /// ## Manual anchor usage
  /// Useful when:
  /// - You already have a trusted time source.
  /// - Offline or cached trusted time is available.
  /// - Unit testing.
  ///
  /// Example:
  /// ```dart
  /// await TrustedTimeService().initialize(
  ///   trustedAnchorUtc: serverTime,
  /// );
  /// ```
  /// ## Throws
  /// Throws an [Exception] if:
  /// - Network request fails.
  /// - Timeout occurs.
  /// - Invalid server response.
  ///
  /// Even if this fails, calls to [now] remain safe by falling back.
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
      final datetimeStr = data['utcTime'] as String;

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
      // Re-throw so caller knows init failed, but subsequent calls to now() will fallback safely.
      throw Exception('Failed to initialize trusted time: $e');
    }
  }

  /// Returns the current trusted UTC time.
  ///
  /// ## Fallback behavior
  /// If the service has not been initialized:
  /// - Returns system UTC time.
  /// - Logs a warning.
  ///
  /// This makes the method safe to call anytime.
  DateTime nowUtc() {
    if (!isInitialized) {
      developer.log(
        'TrustedTimeService not initialized. Falling back to system time.',
        name: 'TrustedTimeService',
        level: 900, // Warning level
      );
      return DateTime.now().toUtc();
    }

    final deltaMillis = _uptime.getUptimeMillis() - _anchorUptimeMillis!;

    return _anchorUtc!.add(Duration(milliseconds: deltaMillis));
  }

  /// Returns the trusted local time using a configurable offset.
  ///
  /// Unlike `DateTime.now()`, this method:
  /// - Does NOT use the device timezone.
  /// - Prevents timezone tampering.
  /// - Allows explicit control of time offset.
  ///
  /// ## Offset priority
  /// 1. Explicit parameters.
  /// 2. Default offset configured in [initialize].
  ///
  /// ## Example
  /// ```dart
  /// final local = TrustedTimeService().now(
  ///   offsetHours: 6,
  /// );
  /// ```
  ///
  /// This is useful when:
  /// - The app must follow a fixed server timezone.
  /// - Time consistency across regions is required.
  DateTime now({int? offsetHours, int? offsetMinutes}) {
    final utc = nowUtc();

    return utc.add(
      Duration(
        hours: offsetHours ?? _defaultOffsetHours,
        minutes: offsetMinutes ?? _defaultOffsetMinutes,
      ),
    );
  }

  /// Clears the current trusted time anchor.
  ///
  /// After calling this:
  /// - The service will behave as uninitialized.
  /// - Calls to [now] and [nowUtc] will fallback.
  /// - [initialize] must be called again.
  ///
  /// Useful when:
  /// - User logs out.
  /// - Security reset is required.
  /// - App needs to refresh trusted time.
  void reset() {
    _anchorUtc = null;
    _anchorUptimeMillis = null;
  }
}
