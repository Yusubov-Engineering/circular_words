import 'package:flutter/widgets.dart';

/// Signature for a function that builds a shell (like a layout with a bottom navigation bar)
/// wrapping the nested [child] router.
typedef AppShellBuilder = Widget Function(BuildContext context, Widget child);
