import 'package:analytics_api/analytics_api.dart';
import 'package:analytics_impl/analytics_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger_api/logger_api.dart';

import 'fakes.dart';

void main() {
  test('the logging backend writes events to the log', () async {
    final logger = RecordingLogger();
    final container = MapContainer()..registerSingleton<LoggerApi>(logger);

    await const AnalyticsModule(backend: LoggingAnalyticsBackend())
        .registerDependencies(container);

    await container.get<AnalyticsApi>().logEvent(
      const AnalyticsEvent('round_finished', parameters: {'score': 24}),
    );
    await container.get<CrashReporterApi>().recordError(
      StateError('boom'),
      null,
      reason: 'loading words',
    );

    expect(logger.lines, [
      'debug event round_finished {score: 24}',
      'error non-fatal: loading words: Bad state: boom',
    ]);
  });

  test(
    'the disabled backend registers both contracts and drops everything',
    () async {
      final container = MapContainer();

      await const AnalyticsModule(backend: DisabledAnalyticsBackend())
          .registerDependencies(container);

      await expectLater(
        container.get<AnalyticsApi>().logEvent(const AnalyticsEvent('x')),
        completes,
      );
      await expectLater(container.get<CrashReporterApi>().log('x'), completes);
    },
  );
}
