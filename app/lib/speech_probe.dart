// Device probe for the speech module. Not part of the app: nothing routes
// here, and `main.dart` is unaffected. Kept past milestone 2 because
// milestone 7 wires the recogniser into the real game and will want to
// re-check the same behaviours on hardware.
//
// Run it against a physical device (the iOS Simulator cannot recognise
// speech, and CI has no microphone):
//
//   cd app && flutter run --flavor dev \
//     --dart-define-from-file=../config/dev.json \
//     -t lib/speech_probe.dart
//
// It exercises exactly what milestone 2 has to demonstrate and nothing else:
// that initialize() reports SpeechReady on a real device, that listen()
// streams partials before the final, that alternates actually arrive, and
// that a silent ten seconds does not tear the session down.

import 'dart:async';

import 'package:dependency_injection_api/dependency_injection_api.dart';
import 'package:dependency_injection_impl/dependency_injection_impl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:speech_api/speech_api.dart';
import 'package:speech_impl/speech_impl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Resolve through the real module rather than newing up the concrete class,
  // so this also proves SpeechModule registers what the game will ask for.
  final DependencyContainer container = GetItContainer();
  await SpeechModule().registerDependencies(container);

  runApp(SpeechProbeApp(recognizer: container<SpeechRecognizerApi>()));
}

class SpeechProbeApp extends StatelessWidget {
  const SpeechProbeApp({required this.recognizer, super.key});

  final SpeechRecognizerApi recognizer;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Speech probe',
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(useMaterial3: true),
    home: SpeechProbeScreen(recognizer: recognizer),
  );
}

class SpeechProbeScreen extends StatefulWidget {
  const SpeechProbeScreen({required this.recognizer, super.key});

  final SpeechRecognizerApi recognizer;

  @override
  State<SpeechProbeScreen> createState() => _SpeechProbeScreenState();
}

class _SpeechProbeScreenState extends State<SpeechProbeScreen> {
  final List<String> _log = [];

  SpeechRecognizerApi get _recognizer => widget.recognizer;

  StreamSubscription<SpeechResult>? _subscription;
  SpeechAvailability? _availability;
  SpeechResult? _last;
  int _partials = 0;
  int _finals = 0;
  bool _busy = false;

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_recognizer.dispose());
    super.dispose();
  }

  void _note(String message) {
    debugPrint('[probe] $message');
    if (mounted) setState(() => _log.insert(0, message));
  }

  Future<void> _initialize() async {
    setState(() => _busy = true);
    final availability = await _recognizer.initialize();

    switch (availability) {
      case SpeechReady(:final locales):
        _note('READY — ${locales.length} locales');
        final english = locales.where((l) => l.startsWith('en')).take(6);
        if (english.isNotEmpty) _note('  en: ${english.join(', ')}');
      case SpeechUnavailable(:final reason):
        _note('UNAVAILABLE — ${reason.name}');
    }

    if (mounted) {
      setState(() {
        _availability = availability;
        _busy = false;
      });
    }
  }

  Future<void> _listen() async {
    await _subscription?.cancel();
    setState(() {
      _partials = 0;
      _finals = 0;
      _last = null;
    });
    _note('--- listening (10s cap) ---');

    final started = DateTime.now();

    _subscription = _recognizer
        .listen(
          maxDuration: const Duration(seconds: 10),
          pauseFor: const Duration(seconds: 3),
          localeId: 'en_US',
        )
        .listen(
          (result) {
            final ms = DateTime.now().difference(started).inMilliseconds;
            setState(() {
              _last = result;
              result.isFinal ? _finals++ : _partials++;
            });
            _note(
              '${result.isFinal ? "FINAL " : "partial"} +${ms}ms '
              '"${result.transcript}"'
              '${result.alternates.isEmpty ? "" : " alts=${result.alternates}"}',
            );
          },
          onError: (Object error) => _note('ERROR $error'),
          onDone: () {
            final ms = DateTime.now().difference(started).inMilliseconds;
            _note(
              '--- closed after ${ms}ms '
              '($_partials partial, $_finals final) ---',
            );
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final ready = _availability is SpeechReady;

    return Scaffold(
      appBar: AppBar(title: const Text('Speech probe — milestone 2')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: _busy ? null : _initialize,
              child: const Text('1. initialize()'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: ready ? _listen : null,
              child: Text(
                ready ? '2. listen() — say a word' : '2. listen() — init first',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: ready ? () => unawaited(_recognizer.stop()) : null,
              child: const Text('stop()'),
            ),
            const SizedBox(height: 16),
            _Summary(
              availability: _availability,
              last: _last,
              partials: _partials,
              finals: _finals,
              isListening: _recognizer.isListening,
            ),
            const Divider(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: _log.length,
                itemBuilder: (context, index) => Text(
                  _log[index],
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.availability,
    required this.last,
    required this.partials,
    required this.finals,
    required this.isListening,
  });

  final SpeechAvailability? availability;
  final SpeechResult? last;
  final int partials;
  final int finals;
  final bool isListening;

  @override
  Widget build(BuildContext context) {
    final result = last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(switch (availability) {
          null => 'not initialised',
          SpeechReady() => 'READY',
          SpeechUnavailable(:final reason) => 'UNAVAILABLE: ${reason.name}',
        }),
        Text('partials: $partials   finals: $finals'),
        if (result != null) ...[
          const SizedBox(height: 8),
          Text(
            result.transcript,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text('confidence ${result.confidence.toStringAsFixed(2)}'),
          Text('candidates: ${result.candidates.toList()}'),
        ],
      ],
    );
  }
}
