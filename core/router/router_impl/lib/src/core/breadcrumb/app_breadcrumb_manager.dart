import 'package:flutter/foundation.dart';

class BreadcrumbItem {
  const BreadcrumbItem({
    required this.id,
    required this.title,
    required this.routePath,
  });

  final String id;
  final String title;
  final String routePath;
}

class AppBreadcrumbManager extends ChangeNotifier {
  final List<BreadcrumbItem> _crumbs = [];

  List<BreadcrumbItem> get crumbs => List.unmodifiable(_crumbs);

  void push(String id, String title, String routePath) {
    final foundedIndex = _crumbs.indexWhere((c) => c.id == id);

    if (foundedIndex >= 0) {
      // 1. Item already exists: ONLY update if the title or route changed
      final existing = _crumbs[foundedIndex];
      if (existing.title != title || existing.routePath != routePath) {
        _crumbs[foundedIndex] = BreadcrumbItem(
          id: id,
          title: title,
          routePath: routePath,
        );
        notifyListeners(); // Rebuild UI only when data actually changes
      }
      // If it exists and hasn't changed, do NOTHING (prevents duplicates)
    } else {
      // 2. Item does not exist: Add it as a new breadcrumb
      _crumbs.add(BreadcrumbItem(id: id, title: title, routePath: routePath));
      notifyListeners();
    }
  }

  void remove(String id) {
    final initialLength = _crumbs.length;
    _crumbs.removeWhere((c) => c.id == id);
    if (_crumbs.length != initialLength) {
      notifyListeners();
    }
  }
}
