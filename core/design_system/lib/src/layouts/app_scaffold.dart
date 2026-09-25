import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../ext/app_theme_ext.dart';
import 'app_scaffold_controller.dart';

const _drawerSettleDuration = Duration(milliseconds: 246);

class const AppScaffold({
  required final Widget body,
  final bool resizeToAvoidBottomInset = true,
  final Widget? drawer,
  final Widget? endDrawer,
  final AppScaffoldController? controller,
  final ValueChanged<bool>? onDrawerChanged,
  final ValueChanged<bool>? onEndDrawerChanged,
  final double drawerBackdropBlur = 8,
  final Color drawerScrimColor = const Color(0x33000000),
  super.key,
}) extends StatefulWidget {
  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  bool _isDrawerOpen = false;

  void _handleDrawerChanged(bool isOpen) {
    setState(() => _isDrawerOpen = isOpen);
    widget.onDrawerChanged?.call(isOpen);
  }

  void _handleEndDrawerChanged(bool isOpen) {
    setState(() => _isDrawerOpen = isOpen);
    widget.onEndDrawerChanged?.call(isOpen);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = widget.resizeToAvoidBottomInset
        ? MediaQuery.viewInsetsOf(context).bottom
        : 0.0;

    final systemBottomBarHeight = MediaQuery.viewPaddingOf(context).bottom;
    final totalBottomPadding = math.max(bottomInset, systemBottomBarHeight);

    return Scaffold(
      key: widget.controller?.scaffoldKey,
      backgroundColor: context.backgroundColors.bgPrimary,
      resizeToAvoidBottomInset: false,
      drawer: widget.drawer,
      endDrawer: widget.endDrawer,
      drawerScrimColor: widget.drawerScrimColor,
      onDrawerChanged: _handleDrawerChanged,
      onEndDrawerChanged: _handleEndDrawerChanged,
      body: TweenAnimationBuilder<double>(
        tween: Tween<double>(
          end: _isDrawerOpen ? widget.drawerBackdropBlur : 0,
        ),
        duration: _drawerSettleDuration,
        curve: Curves.easeOut,
        builder: (context, sigma, child) {
          return ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: child,
          );
        },
        child: Padding(
          padding: EdgeInsets.only(bottom: totalBottomPadding),
          // The bottom inset is paid for here, so the body must not see it
          // again: without this, a `SafeArea` inside the body pads for the
          // home indicator a second time — a dead band under every screen,
          // and worse in landscape, where height is the scarce dimension.
          //
          // One combined query, not three nested `MediaQuery.remove*` calls:
          // each of those reads the query above *this* context, so nesting
          // them would have every layer undo the one before it.
          child: MediaQuery(
            data: MediaQuery.of(context)
                .removeViewInsets(removeBottom: true)
                .removeViewPadding(removeBottom: true)
                .removePadding(removeBottom: true),
            child: widget.body,
          ),
        ),
      ),
    );
  }
}
