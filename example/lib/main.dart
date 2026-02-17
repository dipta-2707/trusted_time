import 'dart:async';

import 'package:flutter/material.dart';
import 'package:trusted_time/trusted_time.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TrustedTimeService _trustedTime = TrustedTimeService();

  Timer? _timer;

  bool _isLoading = true;
  String? _errorMessage;
  DateTime? _currentTime;

  /// Configure your default trusted offset here
  static const int _defaultOffsetHours = 6;

  @override
  void initState() {
    super.initState();
    _initializeTrustedTime();
  }

  Future<void> _initializeTrustedTime() async {
    try {
      await _trustedTime.initialize(defaultOffsetHours: _defaultOffsetHours);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _currentTime = _trustedTime.now();
      });

      _startTicker();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _startTicker() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() {
        _currentTime = _trustedTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    return "${time.year}-${_twoDigits(time.month)}-${_twoDigits(time.day)} "
        "${_twoDigits(time.hour)}:${_twoDigits(time.minute)}:${_twoDigits(time.second)}";
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Trusted Time Example')),
        body: Center(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const CircularProgressIndicator();
    }

    if (_errorMessage != null) {
      return Text(
        'Initialization failed:\n$_errorMessage',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.red),
      );
    }

    if (_currentTime == null) {
      return const Text('No time available');
    }

    return Text(
      _formatTime(_currentTime!),
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }
}
