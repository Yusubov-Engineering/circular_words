import 'package:analytics_impl/analytics_impl.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

PageRoute<void> _page(String? name) => PageRouteBuilder<void>(
  settings: RouteSettings(name: name),
  pageBuilder: (_, _, _) => const SizedBox(),
);

final class _Dialog extends PopupRoute<void> {
  _Dialog() : super(settings: const RouteSettings(name: 'dialog'));

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => const SizedBox();
}

void main() {
  late RecordingAnalytics analytics;
  late AnalyticsRouteObserver observer;

  setUp(() {
    analytics = RecordingAnalytics();
    observer = AnalyticsRouteObserver(analytics: analytics);
  });

  test('a pushed page is a screen view', () {
    observer.didPush(_page('levels'), null);

    expect(analytics.screens, ['levels']);
  });

  test('popping back is a view of the page underneath', () {
    final levels = _page('levels');

    observer.didPop(_page('rosco'), levels);

    expect(analytics.screens, ['levels']);
  });

  test('a replacement is a view of the new page', () {
    observer.didReplace(newRoute: _page('result'), oldRoute: _page('rosco'));

    expect(analytics.screens, ['result']);
  });

  test('dialogs and unnamed pages are not screens', () {
    observer
      ..didPush(_Dialog(), null)
      ..didPush(_page(null), null)
      ..didPush(_page(''), null);

    expect(analytics.screens, isEmpty);
  });

  test('screen names can be mapped, to keep ids out of them', () {
    AnalyticsRouteObserver(
      analytics: analytics,
      screenName: (settings) => settings.name?.split('/').first,
    ).didPush(_page('rosco/b1'), null);

    expect(analytics.screens, ['rosco']);
  });
}
