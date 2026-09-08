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
    return AppStateProvider(
      create: () => ResultController(
        scoreboard: context.locator<RoscoScoreboard>(),
        level: args.level,
        score: args.score,
      ),
      onEffect: _onEffect,
      child: const _ResultView(),
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

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    AppText(
                      title: state.level.label,
                      textAlign: TextAlign.center,
                      style: context.typography.textSm.medium.copyWith(
                        color: context.textColors.textTertiary,
                      ),
                    ),
                    context.spacing.spacingXs.verticalSpace,
                    AppText(
                      title: l10n.resultTitle,
                      textAlign: TextAlign.center,
                      style: context.typography.textLg.regular.copyWith(
                        color: context.textColors.textSecondary,
                      ),
                    ),
                    context.spacing.spacingXl.verticalSpace,
                    _Score(score: state.score),
                    context.spacing.spacingMd.verticalSpace,
                    AppText(
                      title: l10n.resultTimeLeft(state.score.secondsRemaining),
                      textAlign: TextAlign.center,
                      style: context.typography.textMd.regular.copyWith(
                        color: context.textColors.textTertiary,
                      ),
                    ),
                    context.spacing.spacingLg.verticalSpace,
                    _BestLine(state: state),
                    const Spacer(),
                    AppPrimaryButton(
                      title: l10n.resultPlayAgain,
                      onTap: () => unawaited(
                        controller.dispatch(const ResultReplayed()),
                      ),
                    ),
                    context.spacing.spacingMd.verticalSpace,
                    _QuietButton(
                      title: l10n.resultChooseLevel,
                      onTap: () => unawaited(
                        controller.dispatch(const ResultDismissed()),
                      ),
                    ),
                  ],
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
        AppText(
          title: '${score.correct}',
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

    // Minimum, not fixed — see the round screen's status line for why.
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: context.spacing.spacing3Xl),
      child: Center(
        child: AppText(
          title: text,
          textAlign: TextAlign.center,
          style: context.typography.textMd.semiBold.copyWith(color: color),
        ),
      ),
    );
  }
}

/// A secondary action: present, but not competing with the primary one.
class const _QuietButton({
  required final String title,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: title,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.spacing.spacingLg),
        child: AppText(
          title: title,
          textAlign: TextAlign.center,
          style: context.typography.textMd.semiBold.copyWith(
            color: context.textColors.textBrand,
          ),
        ),
      ),
    ),
  );
}
