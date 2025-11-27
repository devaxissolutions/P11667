import 'package:firebase_performance/firebase_performance.dart';

class PerfService {
  static Future<T> trace<T>(String name, Future<T> Function() action) async {
    final trace = FirebasePerformance.instance.newTrace(name);
    await trace.start();
    try {
      final result = await action();
      return result;
    } finally {
      await trace.stop();
    }
  }

  static Future<void> startTrace(String name) async {
    final trace = FirebasePerformance.instance.newTrace(name);
    await trace.start();
  }

  static Future<void> stopTrace(String name) async {
    final trace = FirebasePerformance.instance.newTrace(name);
    await trace.stop();
  }
}
