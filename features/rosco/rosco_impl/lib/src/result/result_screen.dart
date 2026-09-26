import 'dart:async';

import 'package:analytics_api/analytics_api.dart';
import 'package:app_localization/app_localization.dart';
import 'package:dependency_injection_api/dependency_injection_api.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:rosco_api/rosco_api.dart';
import 'package:router_api/router_api.dart';
import 'package:state_manager/state_manager.dart';

import '../domain/word_bank_repository.dart';
import '../router/rosco_result_args.dart';
import '../router/rosco_route_info.dart';
import '../share/result_card.dart';
import '../share/result_sharer.dart';
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
          analytics: context.locator<AnalyticsApi>(),
          repository: context.locator<WordBankRepository>(),
          level: args.level,
          score: args.score,
          setId: args.setId,
          marks: args.marks,
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
      case ShareOutcome(:final result):
        unawaited(_share(context, result));
    }
  }

  /// Paints the result card and opens the share sheet with it.
  ///
  /// Everything read from [context] is read before the first `await`: the
  /// card takes a moment to encode, and the screen may be gone by then.
  Future<void> _share(BuildContext context, ResultState result) async {
    final sharer = context.locator<ResultSharer>();
    final colors = ResultCardColors.of(context);
    final typography = context.typography;
    final l10n = context.localization;
    final text = l10n.shareMessage(
      result.score.correct,
      result.score.total,
      result.level.label,
    );
    // Anchors the sheet on iPad, where it is a popover rather than a sheet.
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null || !box.hasSize
        ? null
        : box.localToGlobal(Offset.zero) & box.size;

    final caption = l10n.scoreSummary(result.score.correct, result.score.total);
    final direction = Directionality.of(context);

    final image = await renderResultCard(
      result: result,
      colors: colors,
      typography: typography,
      appName: 'Circular Words',
      caption: caption,
      textDirection: direction,
    );
    await sharer.share(image: image, text: text, origin: origin);
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
                    // Straight after the score: the words the player could
                    // not find are the most useful thing on this screen,
                    // and the moment right after the round is when they
                    // are still wondering.
                    _MissedWords(state: state, firstBeat: beat),
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
                        title: l10n.resultShare,
                        variant: AppButtonVariant.secondary,
                        onTap: () => unawaited(
                          controller.dispatch(const ResultShared()),
                        ),
                      ),
                    ),
                    context.spacing.spacingSm.verticalSpace,
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

/// The answers to every letter the player did not find.
///
/// Revealed here, not during the round: a letter that runs out of time comes
/// back on the next lap, so naming its word then would spoil it. Once the
/// round is over nothing more can be spoiled, and the reveal is immediate.
class const _MissedWords({
  required final ResultState state,

  /// Where these rows join the screen's entrance sequence.
  required final int firstBeat,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final missed = state.missed;
    // Unknown — the set could not be read back. Name nothing rather than risk
    // naming the wrong word.
    if (missed == null) return const SizedBox.shrink();

    final l10n = context.localization;
    final status = context.statusColors;

    if (missed.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: context.spacing.spacingXl),
        child: AppEntrance(
          index: firstBeat,
          child: AppText(
            title: l10n.resultAllCorrect,
            textAlign: TextAlign.center,
            style: context.typography.textMd.semiBold.copyWith(
              color: status.statusSuccess,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: context.spacing.spacing3Xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppEntrance(
            index: firstBeat,
            child: AppText(
              title: l10n.resultMissedTitle,
              style: context.typography.textMd.semiBold.copyWith(
                color: context.textColors.textSecondary,
              ),
            ),
          ),
          for (final (index, letter) in missed.indexed) ...[
            context.spacing.spacingMd.verticalSpace,
            AppEntrance(
              index: firstBeat + 1 + index,
              child: _MissedWord(letter: letter),
            ),
          ],
        ],
      ),
    );
  }
}

/// One revealed word: its letter, the word, and the clue it answered.
class const _MissedWord({required final ResultLetter letter})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final status = context.statusColors;
    final entry = letter.entry;

    return AppCard(
      // Read as one line: "B, borrow: To take something…".
      semanticsLabel: '${entry.letter}, ${entry.word}: ${entry.definition}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The same red as the letter on the wheel, so the two connect.
          Container(
            constraints: BoxConstraints(
              minWidth: context.sizes.size32,
              minHeight: context.sizes.size32,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: status.statusDanger,
              shape: BoxShape.circle,
            ),
            child: AppText(
              title: entry.letter,
              style: context.typography.textSm.bold.copyWith(
                color: status.statusOnFill,
              ),
            ),
          ),
          context.spacing.spacingLg.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  title: entry.word,
                  style: context.typography.textMd.semiBold.copyWith(
                    color: context.textColors.textPrimary,
                  ),
                ),
                context.spacing.spacingXxs.verticalSpace,
                AppText(
                  title: entry.definition,
                  style: context.typography.textSm.regular.copyWith(
                    color: context.textColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
