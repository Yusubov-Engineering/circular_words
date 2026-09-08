import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rosco_impl/src/domain/word_set.dart';
import 'package:rosco_impl/src/rosco/widgets/rosco_wheel.dart';

const _center = Offset(100, 100);
const _radius = 50.0;

Offset offsetAt(int index, {int count = WordSet.letterCount}) =>
    roscoLetterOffset(
      center: _center,
      radius: _radius,
      index: index,
      count: count,
    );

void main() {
  group('roscoLetterOffset', () {
    // If A is not at twelve o'clock the whole wheel reads wrong, and it is
    // the one position a person will notice immediately.
    test('puts the first letter at the top', () {
      final a = offsetAt(0);

      expect(a.dx, closeTo(_center.dx, 0.001));
      expect(a.dy, closeTo(_center.dy - _radius, 0.001));
    });

    test('runs clockwise', () {
      // A quarter of the way round a 4-letter wheel is three o'clock.
      final east = offsetAt(1, count: 4);

      expect(east.dx, closeTo(_center.dx + _radius, 0.001));
      expect(east.dy, closeTo(_center.dy, 0.001));
    });

    test('every letter sits on the circle', () {
      for (var index = 0; index < WordSet.letterCount; index++) {
        expect(
          (offsetAt(index) - _center).distance,
          closeTo(_radius, 0.001),
          reason: 'letter $index left the ring',
        );
      }
    });

    test('spaces the letters evenly', () {
      final gaps = [
        for (var index = 0; index < WordSet.letterCount; index++)
          (offsetAt((index + 1) % WordSet.letterCount) - offsetAt(index))
              .distance,
      ];

      for (final gap in gaps) {
        expect(gap, closeTo(gaps.first, 0.001));
      }
    });

    test('wraps all the way round exactly once', () {
      // The step after the last letter is the first letter again.
      final wrapped = offsetAt(WordSet.letterCount);

      expect((wrapped - offsetAt(0)).distance, closeTo(0, 0.001));
    });
  });

  group('roscoChipRadius', () {
    // Chips are sized from the circumference so 26 of them never overlap,
    // however large the wheel is drawn.
    test('keeps neighbouring chips apart', () {
      for (final ringRadius in [40.0, 120.0, 300.0]) {
        final chip = roscoChipRadius(
          ringRadius: ringRadius,
          count: WordSet.letterCount,
        );
        final gap =
            (roscoLetterOffset(
                      center: _center,
                      radius: ringRadius,
                      index: 1,
                      count: WordSet.letterCount,
                    ) -
                    roscoLetterOffset(
                      center: _center,
                      radius: ringRadius,
                      index: 0,
                      count: WordSet.letterCount,
                    ))
                .distance;

        expect(
          chip * 2,
          lessThan(gap),
          reason: 'chips touch at ring radius $ringRadius',
        );
      }
    });

    test('scales with the wheel', () {
      final small = roscoChipRadius(ringRadius: 50, count: 26);
      final large = roscoChipRadius(ringRadius: 200, count: 26);

      expect(large, closeTo(small * 4, 0.001));
    });

    test('a fuller wheel gets smaller chips', () {
      expect(
        roscoChipRadius(ringRadius: 100, count: 40),
        lessThan(roscoChipRadius(ringRadius: 100, count: 10)),
      );
    });
  });

  group('the geometry the painter relies on', () {
    // The painter insets the ring by the largest chip it will draw. If that
    // arithmetic is wrong the active chip is clipped at the edge.
    test('an active chip fits inside the box', () {
      const boxRadius = 160.0;
      const activeScale = 1.45;

      final allowance = roscoChipRadius(
        ringRadius: boxRadius,
        count: WordSet.letterCount,
      );
      final ringRadius = boxRadius - allowance * activeScale;
      final chip = roscoChipRadius(
        ringRadius: ringRadius,
        count: WordSet.letterCount,
      );

      expect(ringRadius + chip * activeScale, lessThanOrEqualTo(boxRadius));
      expect(ringRadius, greaterThan(0));
    });

    test('the timer ring stays inside the letters and visible', () {
      const boxRadius = 160.0;
      const ringRadius = boxRadius * 0.85;
      final chip = roscoChipRadius(
        ringRadius: ringRadius,
        count: WordSet.letterCount,
      );
      final timerRadius = ringRadius - chip * 1.9;

      expect(timerRadius, greaterThan(0));
      expect(timerRadius, lessThan(ringRadius - chip));
    });

    test('a full sweep is one whole turn', () {
      expect(2 * pi * 1.0, closeTo(2 * pi, 0.001));
    });
  });
}
