import 'dart:io';

import 'package:feedback_impl/src/feedback_sounds.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the sounds that ship', () {
    test('every cue has a file behind it', () {
      for (final sound in FeedbackSound.values) {
        final file = File('assets/sounds/${sound.fileName}');

        expect(
          file.existsSync(),
          isTrue,
          reason:
              '${sound.name} has no asset. Regenerate them with '
              'tool/sound_authoring/generate_sounds.py.',
        );
        // Small enough to keep in the APK without thinking about it, and big
        // enough to be an actual sound rather than a truncated header.
        expect(file.lengthSync(), greaterThan(1000));
        expect(file.lengthSync(), lessThan(200 * 1024));
      }
    });

    // The prefix is the whole reason package assets resolve in the app. The
    // word bank shipped this bug once already: without `packages/<name>/` a
    // path still works in this package's own tests and fails only once it is
    // running inside the app.
    test('assets are addressed through the package prefix', () {
      expect(AudioPlayersSounds.assetPrefix, startsWith('packages/'));
      expect(AudioPlayersSounds.assetPrefix, contains('feedback_impl'));
      expect(AudioPlayersSounds.assetPrefix, endsWith('/'));
    });

    test('the declared asset folder is the one they live in', () {
      final declared = File('pubspec.yaml').readAsStringSync();

      expect(declared, contains('assets/sounds/'));
      expect(
        AudioPlayersSounds.assetPrefix,
        endsWith('assets/sounds/'),
        reason: 'the prefix and the pubspec must name the same folder',
      );
    });
  });
}
