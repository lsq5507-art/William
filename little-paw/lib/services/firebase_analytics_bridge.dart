import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import 'event_log.dart';

/// Production AnalyticsSink wrapping FirebaseAnalytics.
/// Errors are swallowed so dual-write never crashes the app.
class FirebaseAnalyticsBridge implements AnalyticsSink {
  FirebaseAnalyticsBridge([FirebaseAnalytics? analytics])
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  @override
  void logEvent(String name, {Map<String, Object>? parameters}) {
    try {
      unawaited(
        _analytics.logEvent(name: name, parameters: parameters).catchError(
          (Object e, StackTrace st) {
            debugPrint('FirebaseAnalytics.logEvent failed: $e');
          },
        ),
      );
    } catch (e) {
      debugPrint('FirebaseAnalytics.logEvent sync failed: $e');
    }
  }
}
