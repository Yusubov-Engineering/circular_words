import 'package:flutter/widgets.dart';

/// Signature for a function that builds a page widget given the routing arguments.
typedef AppRouteBuilder<T> = Widget Function(BuildContext context, T args);
