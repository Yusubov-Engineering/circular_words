import 'package:analytics_api/analytics_api.dart';
import 'package:test/test.dart';

final class _RoundFinished extends AnalyticsEvent {
  _RoundFinished({required int score})
    : super('round_finished', parameters: {'score': score});
}

void main() {
  test('an event has no parameters unless it is given some', () {
    const event = AnalyticsEvent('app_opened');

    expect(event.name, 'app_opened');
    expect(event.parameters, isEmpty);
    expect(event.toString(), 'app_opened');
  });

  test('an app defines its own events by extending it', () {
    final event = _RoundFinished(score: 24);

    expect(event.name, 'round_finished');
    expect(event.parameters, {'score': 24});
    expect(event.toString(), 'round_finished {score: 24}');
  });
}
