/// An abstract interface representing a stateful navigation shell (like a Bottom Navigation Bar).
///
/// This completely decouples the UI from the underlying router's implementation.
abstract interface class AppStatefulShell {
  /// The current active tab/branch index.
  int get currentIndex;

  /// Dynamic count of available branches/tabs for the current user role
  int get branchCount;

  /// Navigates to a different tab/branch.
  ///
  /// If [initialLocation] is true, it forces the branch to reset to its initial route.
  void goBranch(int index, {bool initialLocation = false});
}
