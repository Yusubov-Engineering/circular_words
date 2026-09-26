import 'package:analytics_api/analytics_api.dart';
import 'package:rosco_api/rosco_api.dart';

/// The player picked a level to play.
final class LevelSelectedEvent extends AnalyticsEvent {
  LevelSelectedEvent({required CefrLevel level})
    : super('level_selected', parameters: {'level': level.id});
}
