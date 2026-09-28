import 'package:analytics_api/analytics_api.dart';
import 'package:analytics_impl/src/crashlytics_reporter_impl.dart';
import 'package:analytics_impl/src/firebase_analytics_impl.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

final class _FakeAnalytics extends Fake implements FirebaseAnalytics {
  _FakeAnalytics({this.fails = false});

  final bool fails;
  final sent = <(String, Map<String, Object>?)>[];

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
    List<AnalyticsEventItem>? items,
    AnalyticsCallOptions? callOptions,
  }) async {
    if (fails) throw StateError('offline');
    sent.add((name, parameters));
  }

  @override
  Future<void> logScreenView({
    String? screenClass,
    String? screenName,
    Map<String, Object>? parameters,
    AnalyticsCallOptions? callOptions,
  }) async {
    if (fails) throw StateError('offline');
    sent.add(('screen_view', {'screen_name': ?screenName}));
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
    AnalyticsCallOptions? callOptions,
  }) async => throw ArgumentError('name too long');
}

final class _FailingCrashlytics extends Fake implements FirebaseCrashlytics {
  @override
  Future<void> recordError(
    Object? exception,
    StackTrace? stack, {
    Object? reason,
    Iterable<Object> information = const [],
    bool? printDetails,
    bool fatal = false,
  }) async => throw StateError('no network');

  @override
  Future<void> log(String message) async => throw StateError('no network');
}

void main() {
  group('FirebaseAnalyticsImpl', () {
    test('sends an event with its parameters adapted to Firebase', () async {
      final firebase = _FakeAnalytics();
      final analytics = FirebaseAnalyticsImpl(analytics: firebase);

      await analytics.logEvent(
        const AnalyticsEvent(
          'round_finished',
          parameters: {'score': 24, 'spoken': true},
        ),
      );

      final (name, parameters) = firebase.sent.single;
      expect(name, 'round_finished');
      expect(parameters, {'score': 24, 'spoken': 'true'});
    });

    test('an event with no parameters sends none', () async {
      final firebase = _FakeAnalytics();

      await FirebaseAnalyticsImpl(analytics: firebase)
          .logEvent(const AnalyticsEvent('app_opened'));

      expect(firebase.sent, [('app_opened', null)]);
    });

    test('a reserved name is not sent, and says why', () async {
      final firebase = _FakeAnalytics();
      final logger = RecordingLogger();

      await FirebaseAnalyticsImpl(
        analytics: firebase,
        logger: logger,
      ).logEvent(const AnalyticsEvent('session_start'));

      expect(firebase.sent, isEmpty);
      expect(logger.lines.single, contains('reserved'));
    });

    test('never throws, whatever Firebase does', () async {
      final logger = RecordingLogger();
      final analytics = FirebaseAnalyticsImpl(
        analytics: _FakeAnalytics(fails: true),
        logger: logger,
      );

      await expectLater(
        analytics.logEvent(const AnalyticsEvent('round_started')),
        completes,
      );
      await expectLater(analytics.logScreenView('levels'), completes);
      await expectLater(
        analytics.setUserProperty('a_very_long_property_name_indeed', 'x'),
        completes,
      );
      expect(logger.lines, hasLength(3));
      expect(logger.lines, everyElement(startsWith('error')));
    });
  });

  test('CrashlyticsReporterImpl never throws either', () async {
    final logger = RecordingLogger();
    final reporter = CrashlyticsReporterImpl(
      crashlytics: _FailingCrashlytics(),
      logger: logger,
    );

    await expectLater(
      reporter.recordError(StateError('boom'), StackTrace.current),
      completes,
    );
    await expectLater(reporter.log('breadcrumb'), completes);
    expect(logger.lines, hasLength(2));
  });
}
