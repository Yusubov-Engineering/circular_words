import 'dart:async';

import 'package:app_localization/app_localization.dart';
import 'package:dependency_injection_api/dependency_injection_api.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:rosco_api/rosco_api.dart';
import 'package:router_api/router_api.dart';
import 'package:state_manager/state_manager.dart';

import '../router/rosco_result_args.dart';
import '../router/rosco_route_info.dart';
import 'result_controller.dart';

/// {@template result_screen}
/// How the round went, and the way back in.
///
/// Reached by *replacing* the round rather than stacking on it, so the back
/// gesture returns to the level picker. A finished round is not somewhere a
/// player can be sent back to: its clock has stopped and its letters are
/// spent.
/// {@endtemplate}
class const ResultScreen({required final RoscoResultArgs args, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Still in the level's colour: the result belongs to the round it ends.
    return AppAccentScope(
      accent: args.level.accent,
      child: AppStateProvider(
        create: () => ResultController(
          scoreboard: context.locator<RoscoScoreboard>(),
          level: args.level,
          score: args.score,
        ),
        onEffect: _onEffect,
        child: const _ResultView(),
      ),
    );
  }

  void _onEffect(BuildContext context, ResultEffect effect) {
    switch (effect) {
      case ReplayRound(:final level):
        // Replacing again, so a run of rounds cannot grow the stack.
        unawaited(
          context.navigation.replaceRoute(
            AppRouteRequest(
              routeInfo: RoscoRouteInfo.game,
              pathParameters: {'level': level.id},
            ),
          ),
        );
      case LeaveResult():
        context.navigation.popRoute();
    }
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: ColoredBox(
        color: context.backgroundColors.bgPrimary,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(context.spacing.spacingXl),
            child: AppControllerBuilder<ResultController>(
              builder: (context, controller) {
                final state = controller.state;
                final l10n = context.localization;

                // Everything arrives in reading order — where you were, how
                // you did, what next — each a beat after the last, so the eye
                // is led through the screen rather than handed all of it at
                // once. The beats run on across both panes in landscape.
                var beat = 0;
                Widget enter(Widget child) =>
                    AppEntrance(index: beat++, child: child);

                Widget summary() => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    enter(
                      AppText(
                        title: state.level.label,
                        textAlign: TextAlign.center,
                        style: context.typography.textSm.bold.copyWith(
                          color: context.accentColors.accentText,
                        ),
                      ),
                    ),
                    context.spacing.spacingXs.verticalSpace,
                    enter(
                      AppText(
                        title: l10n.resultTitle,
                        textAlign: TextAlign.center,
                        style: context.typography.textLg.regular.copyWith(
                          color: context.textColors.textSecondary,
                        ),
                      ),
                    ),
                    context.spacing.spacingXl.verticalSpace,
                    enter(_Score(score: state.score)),
                    context.spacing.spacingMd.verticalSpace,
                    enter(
                      AppText(
                        title: l10n.resultTimeLeft(
                          state.score.secondsRemaining,
                        ),
                        textAlign: TextAlign.center,
                        style: context.typography.textMd.regular.copyWith(
                          color: context.textColors.textTertiary,
                        ),
                      ),
                    ),
                    context.spacing.spacingLg.verticalSpace,
                    _BestLine(state: state),
                  ],
                );

                Widget actions() => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    enter(
                      AppButton(
                        title: l10n.resultPlayAgain,
                        onTap: () => unawaited(
                          controller.dispatch(const ResultReplayed()),
                        ),
                      ),
                    ),
                    context.spacing.spacingMd.verticalSpace,
                    enter(
                      AppButton(
                        title: l10n.resultChooseLevel,
                        variant: AppButtonVariant.quiet,
                        onTap: () => unawaited(
                          controller.dispatch(const ResultDismissed()),
                        ),
                      ),
                    ),
                  ],
                );

                // Both arrangements fill the screen when they can and scroll
                // when they cannot, so a large font or a short screen pushes
                // the buttons down rather than off the edge.
                return AppAdaptiveLayout(
                  // Upright: the summary centred in the space above the
                  // buttons, which sit where a thumb reaches.
                  portrait: (context) => AppFillScroll(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [const SizedBox.shrink(), summary(), actions()],
                    ),
                  ),
                  // On its side there is not the height to stack both, so
                  // the result and what to do next sit beside each other.
                  landscape: (context) => Row(
                    children: [
                      Expanded(
                        child: AppFillScroll(child: Center(child: summary())),
                      ),
                      context.spacing.spacing3Xl.horizontalSpace,
                      Expanded(
                        child: AppFillScroll(child: Center(child: actions())),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// The number the player came for.
class const _Score({required final LevelScore score}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final status = context.statusColors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        // Counted up rather than shown: the number is the payoff, and
        // arriving at it is part of the moment.
        AppCountUp(
          value: score.correct,
          style: context.typography.textLg.copyWith(
            fontSize: 72,
            fontWeight: FontWeight.w700,
            // The one green thing on the screen, so the eye lands on the
            // number that is actually the achievement.
            color: status.statusSuccess,
          ),
        ),
        AppText(
          title: ' / ${score.total}',
          style: context.typography.textLg.regular.copyWith(
            fontSize: 28,
            color: context.textColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

/// Either "you beat it" or what there is to beat.
class const _BestLine({required final ResultState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;

    // Nothing at all while the save is in flight: a best line that appears and
    // then corrects itself is worse than one that arrives a moment late.
    if (state.isSaving) return SizedBox(height: context.spacing.spacing3Xl);

    final best = state.best;
    final (text, color) = state.isNewBest
        ? (l10n.resultNewBest, context.statusColors.statusSuccess)
        : (
            best == null ? '' : l10n.resultBest(best.correct, best.total),
            context.textColors.textTertiary,
          );

    final line = AppText(
      title: text,
      textAlign: TextAlign.center,
      style: context.typography.textMd.semiBold.copyWith(color: color),
    );

    // Minimum, not fixed — see the round screen's status line for why.
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: context.spacing.spacing3Xl),
      // It arrives once the save lands, so it enters on its own rather than
      // with the rest; a new best is the one line worth a flourish.
      child: Center(
        child: AppEntrance(
          child: state.isNewBest ? _NewBestFlourish(child: line) : line,
        ),
      ),
    );
  }
}

/// Swells once when it appears — a new best is worth a moment.
class const _NewBestFlourish({required final Widget child})
    extends StatefulWidget {
  @override
  State<_NewBestFlourish> createState() => _NewBestFlourishState();
}

class _NewBestFlourishState extends State<_NewBestFlourish> {
  /// Flipped once after the first frame, which is the change `AppPop`
  /// animates on; it never pops on first build by design.
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) =>
      AppPop(trigger: _shown, amount: 0.12, child: widget.child);
}
