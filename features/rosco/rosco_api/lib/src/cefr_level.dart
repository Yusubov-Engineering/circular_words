/// The six CEFR levels the game is graded by.
///
/// This lives in `rosco_api` rather than in `levels_api` because the
/// dependency runs *levels → rosco*: the picker asks the game's launcher for a
/// route, so the launcher's parameter type has to be visible to the caller.
/// Putting it in `levels_api` would force `rosco` to depend on `levels` and
/// close the loop.
enum CefrLevel {
  a1('a1'),
  a2('a2'),
  b1('b1'),
  b2('b2'),
  c1('c1'),
  c2('c2');

  const CefrLevel(this.id);

  /// Stable, lowercase identifier.
  ///
  /// Used in the route path (`/rosco/b1`), the word-bank asset name
  /// (`assets/words/b1.json`) and the storage key for a best score, so it must
  /// not change once scores exist on a device.
  final String id;

  /// Display label — `A1`, `B2`. Not localized: CEFR codes are the same in
  /// every language, unlike the descriptions beside them.
  String get label => id.toUpperCase();

  /// Parses [id] back into a level, or `null` when it names nothing.
  ///
  /// Returns null rather than throwing because the commonest caller is route
  /// parsing, where a hand-typed URL is a redirect, not a crash.
  static CefrLevel? tryParse(String? id) {
    if (id == null) return null;
    final needle = id.toLowerCase();
    for (final level in values) {
      if (level.id == needle) return level;
    }
    return null;
  }
}
