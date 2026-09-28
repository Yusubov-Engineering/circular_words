import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:state_manager/state_manager.dart';

final class const CountState({final int count = 0, final String label = 'a'}) {
  CountState copyWith({int? count, String? label}) =>
      CountState(count: count ?? this.count, label: label ?? this.label);
}

sealed class CountEvent {
  const CountEvent();
}

final class Incremented extends CountEvent {
  const Incremented();
}

final class Relabelled extends CountEvent {
  const Relabelled();
}

final class Finished extends CountEvent {
  const Finished();
}

sealed class CountEffect {
  const CountEffect();
}

final class const Done({required final int at}) extends CountEffect;

final class Started extends CountEffect {
  const Started();
}

final class TestController
    extends AppStateController<CountState, CountEvent, CountEffect> {
  TestController({this.emitOnInit = false}) : super(const CountState());

  final bool emitOnInit;
  int disposeCount = 0;

  @override
  Future<void> onInit() async {
    if (emitOnInit) emitEffect(const Started());
  }

  @override
  Future<void> onEvent(CountEvent event) async {
    switch (event) {
      case Incremented():
        emit(state.copyWith(count: state.count + 1));
      case Relabelled():
        emit(state.copyWith(label: 'b'));
      case Finished():
        emitEffect(Done(at: state.count));
    }
  }

  @override
  void dispose() {
    disposeCount++;
    super.dispose();
  }
}

/// Pumps [child] under a provider, exposing the controller it created.
Widget _host({
  required Widget child,
  required void Function(TestController) onCreate,
  void Function(BuildContext context, CountEffect effect)? onEffect,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: AppStateProvider(
      create: () {
        final controller = TestController();
        onCreate(controller);
        return controller;
      },
      onEffect: onEffect,
      child: child,
    ),
  );
}

void main() {
  group('AppControllerBuilder', () {
    testWidgets('resolves the controller from the provider and rebuilds', (
      tester,
    ) async {
      late TestController controller;
      var builds = 0;

      await tester.pumpWidget(
        _host(
          onCreate: (c) => controller = c,
          child: AppControllerBuilder<TestController>(
            builder: (context, controller) {
              builds++;
              return Text('${controller.state.count}');
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
      expect(builds, 1);

      await controller.dispatch(const Incremented());
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
      expect(builds, 2);
    });

    testWidgets('stops listening once removed from the tree', (tester) async {
      late TestController controller;

      await tester.pumpWidget(
        _host(
          onCreate: (c) => controller = c,
          child: AppControllerBuilder<TestController>(
            builder: (context, controller) => Text('${controller.state.count}'),
          ),
        ),
      );
      await tester.pumpWidget(const SizedBox.shrink());

      // A listener surviving disposal would throw here.
      expect(controller.dispatch(const Incremented()), completes);
    });
  });

  group('AppControllerSelector', () {
    testWidgets('rebuilds only when the selected slice changes', (
      tester,
    ) async {
      late TestController controller;
      var builds = 0;

      await tester.pumpWidget(
        _host(
          onCreate: (c) => controller = c,
          child: AppControllerSelector<TestController, int>(
            select: (controller) => controller.state.count,
            builder: (context, count) {
              builds++;
              return Text('$count');
            },
          ),
        ),
      );

      expect(builds, 1);

      // Touches `label`, not `count` — must not rebuild.
      await controller.dispatch(const Relabelled());
      await tester.pump();
      expect(builds, 1);

      await controller.dispatch(const Incremented());
      await tester.pump();
      expect(builds, 2);
      expect(find.text('1'), findsOneWidget);
    });
  });

  group('AppStateProvider', () {
    testWidgets('delivers effects to onEffect', (tester) async {
      late TestController controller;
      final received = <CountEffect>[];
      void onEffect(BuildContext context, CountEffect effect) =>
          received.add(effect);

      await tester.pumpWidget(
        _host(
          onCreate: (c) => controller = c,
          onEffect: onEffect,
          child: const SizedBox.shrink(),
        ),
      );

      await controller.dispatch(const Incremented());
      await controller.dispatch(const Finished());
      await tester.pump();

      // Effects are plain classes without `==`, so match on shape.
      expect(received, hasLength(1));
      expect(received.single, isA<Done>().having((e) => e.at, 'at', 1));
    });

    testWidgets('an effect emitted from onInit is not dropped', (tester) async {
      final received = <CountEffect>[];
      // A named handler, not a closure: a closure parameter infers as
      // `Object?` and loses the effect type. See AppStateProvider's docs.
      void onEffect(BuildContext context, CountEffect effect) =>
          received.add(effect);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: AppStateProvider(
            create: () => TestController(emitOnInit: true),
            onEffect: onEffect,
            child: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pump();

      expect(received, [const Started()]);
    });

    testWidgets('disposes the controller it created', (tester) async {
      late TestController controller;

      await tester.pumpWidget(
        _host(onCreate: (c) => controller = c, child: const SizedBox.shrink()),
      );
      await tester.pumpWidget(const SizedBox.shrink());

      expect(controller.disposeCount, 1);
    });
  });
}
