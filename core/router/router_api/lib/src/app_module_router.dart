import 'app_module_routes.dart';

/// The contract that all feature modules must implement to register their routes.
///
/// This allows for a decentralized routing architecture where each module
/// is responsible for its own navigation graph.
abstract interface class AppModuleRouter {
  /// Returns a list of top-level routes provided by this module.
  List<AppModuleRoute> get routes;
}
