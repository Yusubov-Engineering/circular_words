/// Exposes only the ability to retrieve dependencies.
abstract class DependencyLocator {
  T get<T extends Object>();
  T getWithName<T extends Object>(String name);
  T call<T extends Object>();
}
