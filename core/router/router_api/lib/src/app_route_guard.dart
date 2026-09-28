import 'dart:async';

import 'package:flutter/widgets.dart';

import 'app_route_arguments.dart';
import 'app_route_request.dart';

/// An interface for protecting routes.
abstract interface class AppRouteGuard {
  /// Evaluates whether the current route can be activated.
  ///
  /// * Return `null` to allow the navigation to proceed.
  /// * Return an [AppRouteRequest] to redirect the user to a different route.
  FutureOr<AppRouteRequest?> redirect(
    BuildContext context,
    AppRouteArguments args,
  );
}
