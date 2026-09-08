import 'dart:async';

import 'package:app_localization/app_localization.dart';
import 'package:dependency_injection_api/dependency_injection_api.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:rosco_api/rosco_api.dart';
import 'package:router_api/router_api.dart';
import 'package:state_manager/state_manager.dart';

import 'levels_controller.dart';
import 'widgets/level_card.dart';
import 'widgets/sound_toggle.dart';

/// {@template levels_screen}
/// The app's entry screen: pick a CEFR level, start a round.
/// {@endtemplate}
class LevelsScreen extends StatefulWidget {
  /// {@macro levels_screen}
  const LevelsScreen({super.key});

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  /// The controller this screen created.
  ///
  /// Held because `onEffect` receives the provider's *own* context, which sits
  /// above the scope the provider builds — so `context.controllerOf` asserts
  /// there rather than resolving. Anything an effect handler needs to dispatch
  /// back into the controller has to reach it this way. The provider still
  /// owns the controller's lifetime; this is a borrowed reference, never
  /// disposed here.
  LevelsController? _controller;

  @override
  Widget build(BuildContext context) {
    return AppStateProvider(
      // The scoreboard is passed in rather than resolved inside the
      // controller, which is what keeps the controller testable with a fake.
      create: () {
        final controller = LevelsController(
          scoreboard: context.locator<RoscoApi>().scoreboard,
        );
        _controller = controller;
        return controller;
      },
      onEffect: _onEffect,
      child: const _LevelsView(),
    );
  }

  // Annotating `effect` is what types the switch. Left off, the parameter
  // infers as `Object?` and exhaustiveness stops applying.
  void _onEffect(BuildContext context, LevelsEffect effect) {
    switch (effect) {
      // Cross-module navigation: resolve the other feature's facade and let
      // *it* say where its screens live. This module never names a path
      // belonging to `rosco`, and never imports `rosco_impl`.
      case StartRound(:final level):
        final rosco = context.locator<RoscoApi>();

        unawaited(
          context.navigation
              .pushRoute(rosco.launcher.game(level: level))
              .then(
                // A round just ended, so a best score may have changed. That is
                // the only moment it can change while this screen exists, which
                // is why the refresh hangs off the push rather than off the
                // screen's lifecycle.
                (_) => _controller?.dispatch(const LevelsRefreshed()),
              ),
        );
    }
  }
}

class _LevelsView extends StatelessWidget {
  const _LevelsView();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: ColoredBox(
        color: context.backgroundColors.bgPrimary,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(context.spacing.spacingXl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppText(
                        title: context.localization.levelsTitle,
                        style: context.typography.displaySm.bold.copyWith(
                          color: context.textColors.textPrimary,
                        ),
                      ),
                    ),
                    // The one place to silence the game. It lives on the way
                    // in rather than inside a round, where a player under a
                    // ten-second clock should not be hunting for a setting.
                    const SoundToggle(),
                  ],
                ),
                context.spacing.spacingXs.verticalSpace,
                AppText(
                  title: context.localization.levelsSubtitle,
                  style: context.typography.textMd.regular.copyWith(
                    color: context.textColors.textTertiary,
                  ),
                ),
                context.spacing.spacingXl.verticalSpace,
                const Expanded(child: _LevelList()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelList extends StatelessWidget {
  const _LevelList();

  @override
  Widget build(BuildContext context) {
    return AppControllerBuilder<LevelsController>(
      builder: (context, controller) {
        final state = controller.state;

        // The six levels are a fixed list, so there is no empty state to
        // design — only the moment before the stored scores have been read.
        if (state.isLoading) {
          return Center(
            child: AppText(
              title: context.localization.loading,
              style: context.typography.textMd.regular.copyWith(
                color: context.textColors.textTertiary,
              ),
            ),
          );
        }

        return ListView.separated(
          itemCount: state.entries.length,
          separatorBuilder: (context, _) =>
              context.spacing.spacingMd.verticalSpace,
          itemBuilder: (context, index) {
            final entry = state.entries[index];

            return LevelCard(
              entry: entry,
              onTap: () =>
                  controller.dispatch(LevelSelected(level: entry.level)),
            );
          },
        );
      },
    );
  }
}
