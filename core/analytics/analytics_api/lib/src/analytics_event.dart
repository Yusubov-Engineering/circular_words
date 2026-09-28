/// {@template analytics_event}
/// Something worth counting, as a name and a few parameters.
///
/// **Each app defines its own events**, usually one subclass per event in the
/// feature that owns it, so the names live next to the code that fires them:
///
/// ```dart
/// final class RoundFinished extends AnalyticsEvent {
///   RoundFinished({required String level, required int score})
///     : super('round_finished', parameters: {'level': level, 'score': score});
/// }
/// ```
///
/// This package deliberately knows no event names — that is what lets every
/// app share it.
///
/// Names are `snake_case`: letters, digits and underscores, starting with a
/// letter, at most 40 characters. Parameter values are `String`, `num` or
/// `bool`. Implementations adapt or drop anything outside that rather than
/// throw, but an event that follows the rules arrives unchanged everywhere.
///
/// Never put what a user typed or said into a parameter. It turns an event
/// count into personal data.
/// {@endtemplate}
class const AnalyticsEvent(
  /// The event's name, `snake_case`.
  final String name, {

  /// Extra detail, keyed by `snake_case` names.
  final Map<String, Object> parameters = const {},
}) {
  @override
  String toString() => parameters.isEmpty ? name : '$name $parameters';
}
