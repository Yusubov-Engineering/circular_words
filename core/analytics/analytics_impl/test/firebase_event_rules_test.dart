import 'package:analytics_impl/src/firebase_event_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const rules = FirebaseEventRules();

  group('event names', () {
    test('accepts snake_case', () {
      expect(rules.rejectEventName('round_finished'), isNull);
      expect(rules.rejectEventName('level2_selected'), isNull);
    });

    test('rejects what Firebase would drop', () {
      expect(rules.rejectEventName(''), isNotNull);
      expect(rules.rejectEventName('2nd_round'), isNotNull);
      expect(rules.rejectEventName('round-finished'), isNotNull);
      expect(rules.rejectEventName('a' * 41), isNotNull);
      expect(rules.rejectEventName('firebase_round'), isNotNull);
      expect(rules.rejectEventName('ga_round'), isNotNull);
    });

    test('rejects the names Firebase logs itself', () {
      expect(rules.rejectEventName('session_start'), contains('reserved'));
      expect(rules.rejectEventName('error'), contains('reserved'));
    });
  });

  group('parameters', () {
    test('numbers and short strings pass unchanged', () {
      final result = rules.adaptParameters({'score': 24, 'level': 'b1'});

      expect(result.parameters, {'score': 24, 'level': 'b1'});
      expect(result.dropped, isEmpty);
    });

    test('a bool is sent as text, which Firebase accepts', () {
      final result = rules.adaptParameters({'spoken': true});

      expect(result.parameters, {'spoken': 'true'});
    });

    test('a long string is cut to the limit', () {
      final result = rules.adaptParameters({'clue': 'x' * 150});

      expect(
        result.parameters['clue'],
        'x' * FirebaseEventRules.maxStringLength,
      );
    });

    test('bad names and unsupported values are dropped, with a reason', () {
      final result = rules.adaptParameters({
        'ok': 1,
        'bad-name': 2,
        'google_id': 3,
        'when': DateTime(2026),
      });

      expect(result.parameters, {'ok': 1});
      expect(result.dropped, hasLength(3));
    });

    test('anything past the 25th parameter is dropped', () {
      final result = rules.adaptParameters({
        for (var i = 0; i < 30; i++) 'p$i': i,
      });

      expect(result.parameters, hasLength(FirebaseEventRules.maxParameters));
      expect(result.dropped, hasLength(5));
    });
  });
}
