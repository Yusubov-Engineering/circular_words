import 'dart:async';

import 'package:app_localization/app_localization.dart';
import 'package:dependency_injection_api/dependency_injection_api.dart';
import 'package:design_system/design_system.dart';
import 'package:feedback_api/feedback_api.dart';
import 'package:flutter/widgets.dart';
import 'package:rosco_api/rosco_api.dart';
import 'package:router_api/router_api.dart';
import 'package:speech_api/speech_api.dart';
import 'package:state_manager/state_manager.dart';

import '../domain/word_bank_repository.dart';
import '../router/rosco_result_args.dart';
import '../router/rosco_route_info.dart';
import '../shared/mic_l10n.dart';
import '../shared/rosco_failure_l10n.dart';
import 'mic_controller.dart';
import 'rosco_controller.dart';
import 'widgets/mic_button.dart';
import 'widgets/rosco_wheel.dart';

/// {@template rosco_screen}
/// A round of the game.
///
/// Two controllers, nested deliberately. `RoscoController` owns every rule
/// that decides the outcome and knows nothing about microphones;
/// [MicController] owns the negotiation with the platform and knows nothing
/// about the rules. They meet in one place — `_onMicEffect` below, which turns
/// a transcript into an answer — and that single seam is what keeps a whole
/// round playable in a unit test with no microphone at all.
/// {@endtemplate}
class const RoscoScreen({required final CefrLevel level, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppStateProvider(
      create: () => RoscoController(
        level: level,
        repository: context.locator<WordBankRepository>(),
      ),
      onEffect: _onRoscoEffect,
      // Inside the round's provider, so the bridge below can reach the round.
      child: AppStateProvider(
        create: () => MicController(
          recognizer: context.locator<SpeechRecognizerApi>(),
          // Long enough that the microphone is rarely reopened, short enough
          // that the platform stays in the mode the plugin can hear. See
          // `kMicSessionSeconds` for the measurements behind the number.
          sessionLength: const Duration(seconds: kMicSessionSeconds),
        ),
        onEffect: _onMicEffect,
        child: const _RoscoView(),
      ),
    );
  }

  // Annotating `effect` is what types the switch. Left off, the parameter
  // infers as `Object?` and exhaustiveness stops applying.
  void _onRoscoEffect(BuildContext context, RoscoEffect effect) {
    final feedback = context.locator<GameFeedbackApi>();

    switch (effect) {
      case RoscoAccepted():
        unawaited(feedback.correct());
      case RoscoRejected():
        unawaited(feedback.rejected());
      case RoscoTimedOut():
        unawaited(feedback.wrong());
      case RoscoFinished(:final score):
        unawaited(feedback.finished());
        // Replacing, not pushing: a finished round has a stopped clock and no
        // letters left, so it is not somewhere the back gesture should be
        // able to return to.
        unawaited(
          context.navigation.replaceRoute(
            AppRouteRequest(
              routeInfo: RoscoRouteInfo.result,
              pathParameters: {'level': level.id},
              queryParameters: RoscoResultArgs(
                level: level,
                score: score,
              ).toQuery(),
            ),
          ),
        );
    }
  }

  /// The one place speech becomes gameplay.
  ///
  /// `context` here is the mic provider's own — above its scope, below the
  /// round's — which is exactly why the lookup finds `RoscoController` and
  /// would not find `MicController`.
  void _onMicEffect(BuildContext context, MicEffect effect) {
    switch (effect) {
      case MicTranscribed(
        :final transcript,
        :final alternates,
        :final tentative,
      ):
        unawaited(
          context.controllerOf<RoscoController>().dispatch(
            RoscoAnswered(
              answer: transcript,
              alternates: alternates,
              tentative: tentative,
            ),
          ),
        );
    }
  }
}

class _RoscoView extends StatelessWidget {
  const _RoscoView();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: ColoredBox(
        color: context.backgroundColors.bgPrimary,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(context.spacing.spacingXl),
            child: AppControllerBuilder<RoscoController>(
              builder: (context, controller) {
                final state = controller.state;

                if (state.isLoading) {
                  return _Centered(text: context.localization.loading);
                }

                final failure = state.failure;
                if (failure != null) {
                  return _Centered(text: failure.message(context));
                }

                final current = state.current;
                if (current == null || state.isOver) {
                  return _Centered(
                    text: context.localization.scoreSummary(
                      state.correctCount,
                      state.slots.length,
                    ),
                  );
                }

                return _RoundBody(state: state, controller: controller);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class const _RoundBody({
  required final RoscoState state,
  required final RoscoController controller,
}) extends StatefulWidget {
  @override
  State<_RoundBody> createState() => _RoundBodyState();
}

class _RoundBodyState extends State<_RoundBody> {
  final _input = TextEditingController();

  /// The player asked for the keyboard. Distinct from the field being *shown*:
  /// an unusable microphone shows it whether they asked or not.
  bool _typing = false;

  /// Captured rather than looked up on demand, because [dispose] runs too late
  /// to read an inherited widget and the microphone has to be told to stop.
  MicController? _mic;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final mic = context.controllerOf<MicController>();
    if (identical(mic, _mic)) return;
    _mic = mic;

    // This body exists only once a letter is on screen, which makes it the
    // right moment to ask for the microphone: the player has chosen a level,
    // the round has loaded, and there is something to say.
    unawaited(mic.dispatch(const MicRequested()));

    // Warmed here rather than at app start, for the same reason: decoding
    // three files costs nothing next to a round, and everything at launch.
    unawaited(context.locator<GameFeedbackApi>().initialize());
  }

  @override
  void didUpdateWidget(_RoundBody old) {
    super.didUpdateWidget(old);

    final before = old.state;
    final now = widget.state;
    // The lap matters as much as the index: a passed letter comes round again
    // at the same place on the wheel, and it is a new prompt when it does.
    if (before.currentIndex == now.currentIndex && before.lap == now.lap) {
      return;
    }

    _input.clear();
    unawaited(_mic?.dispatch(const MicPromptChanged()));
  }

  @override
  void dispose() {
    _input.dispose();
    // The round is over or the screen is going. Without this the microphone
    // keeps re-opening sessions behind the score.
    unawaited(_mic?.dispatch(const MicDismissed()));
    super.dispose();
  }

  void _submit() {
    final answer = _input.text.trim();
    if (answer.isEmpty) return;

    _input.clear();
    unawaited(widget.controller.dispatch(RoscoAnswered(answer: answer)));
  }

  void _pass() {
    _input.clear();
    unawaited(widget.controller.dispatch(const RoscoPassed()));
  }

  void _toggleMic(MicController mic) => unawaited(
    mic.dispatch(
      mic.state.enabled ? const MicDismissed() : const MicRequested(),
    ),
  );

  /// Switching between speaking and typing turns the microphone off and on
  /// with it: an open session behind a keyboard hears the room, not a player.
  void _toggleTyping(MicController mic) {
    setState(() => _typing = !_typing);
    unawaited(
      mic.dispatch(_typing ? const MicDismissed() : const MicRequested()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final current = state.current!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText(
          title:
              '${state.level.label} · ${context.localization.lap(state.lap)} · '
              '${state.remainingPool}s · ${state.correctCount}',
          style: context.typography.textSm.medium.copyWith(
            color: context.textColors.textTertiary,
          ),
        ),
        context.spacing.spacingLg.verticalSpace,
        // The wheel is the screen's subject, so it takes the room that is
        // going spare rather than a fixed height.
        Flexible(
          child: Center(
            child: RoscoWheel(
              slots: state.slots,
              activeIndex: state.currentIndex,
              letterProgress: state.letterRemaining / kLetterCapSeconds,
              centerLabel: '${state.letterRemaining}',
              semanticsLabel: context.localization.roscoWheelSemantics(
                current.letter,
                state.letterRemaining,
                state.correctCount,
                state.slots.length,
              ),
            ),
          ),
        ),
        context.spacing.spacingLg.verticalSpace,
        // Cross-fading on the letter, not the text, so re-showing a passed
        // letter's clue animates too.
        // Flexible so a long clue at a large font scale takes room from the
        // wheel — which can afford it — rather than from the layout.
        Flexible(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Semantics(
              key: ValueKey('${current.letter}-${state.lap}'),
              // A new clue is the one change on this screen a player *must* be
              // told about, and it arrives without them touching anything.
              liveRegion: true,
              // Scrolls only when it has to. At an ordinary font scale a clue
              // is two lines and this is inert; at 2x it is the difference
              // between a readable clue and a clipped one — and truncating the
              // clue would make the letter unanswerable.
              child: SingleChildScrollView(
                child: SizedBox(
                  width: double.infinity,
                  child: AppText(
                    title: current.entry.definition,
                    textAlign: TextAlign.center,
                    style: context.typography.textLg.regular.copyWith(
                      color: context.textColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        AppControllerBuilder<MicController>(builder: _answerArea),
      ],
    );
  }

  Widget _answerArea(BuildContext context, MicController mic) {
    final l10n = context.localization;
    final micState = mic.state;
    final blocked = micState.status == MicStatus.unavailable;
    final typing = _typing || blocked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusLine(state: widget.state, mic: micState, typing: typing),
        if (typing) ...[
          AppOutlinedTextField(
            controller: _input,
            hintText: widget.state.current!.letter,
          ),
          context.spacing.spacingMd.verticalSpace,
          Row(
            children: [
              Expanded(
                child: AppPrimaryButton(title: l10n.answer, onTap: _submit),
              ),
              context.spacing.spacingMd.horizontalSpace,
              Expanded(
                child: AppPrimaryButton(title: l10n.pass, onTap: _pass),
              ),
            ],
          ),
        ] else
          Row(
            children: [
              MicButton(
                status: micState.status,
                onTap: () => _toggleMic(mic),
                // Names the control, nothing more: the on/off state reaches
                // the player through the button's `toggled` semantics, and
                // repeating the status line here had a screen reader saying
                // "Listening" twice in a row.
                semanticsLabel: l10n.microphone,
              ),
              context.spacing.spacingMd.horizontalSpace,
              Expanded(
                child: AppPrimaryButton(title: l10n.pass, onTap: _pass),
              ),
            ],
          ),
        // With no microphone to go back to, offering the choice would be a
        // button that cannot do anything.
        if (!blocked) ...[
          context.spacing.spacingSm.verticalSpace,
          _TextButton(
            title: typing ? l10n.useMic : l10n.typeInstead,
            onTap: () => _toggleTyping(mic),
          ),
        ],
      ],
    );
  }
}

/// The one line between the clue and the controls.
///
/// It has four things to say and room for one, so they are ranked by how much
/// the player needs them *now*: why the microphone is dead, then what it is
/// hearing this second, then what was just turned down, then what it is
/// waiting for.
class const _StatusLine({
  required final RoscoState state,
  required final MicState mic,

  /// Whether the keyboard is the way in right now. Prompts about a microphone
  /// that is not on screen are worse than no prompt at all.
  required final bool typing,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;
    final reason = mic.reason;

    // The third element is how many lines the message is worth. A transcript
    // is one line by design — it is a fragment, and wrapping it would shove
    // the controls down mid-utterance. An explanation of why the microphone is
    // gone is a whole sentence, and clipping it leaves the player reading
    // "Type your" with no idea what to do.
    final (text, color, lines) = switch (mic.status) {
      MicStatus.unavailable when reason != null => (
        reason.message(context),
        context.textColors.textError,
        3,
      ),
      _ when mic.heard.isNotEmpty => (
        mic.heard,
        context.textColors.textPrimary,
        1,
      ),
      _ when state.lastRejected != null => (
        state.lastRejected!,
        context.textColors.textError,
        1,
      ),
      // Typing, with nothing to report: the field below says everything.
      _ when typing => ('', context.textColors.textTertiary, 1),
      MicStatus.listening => (
        l10n.micListening,
        context.textColors.textTertiary,
        1,
      ),
      _ => (l10n.micIdle, context.textColors.textTertiary, 1),
    };

    // A *minimum* height, not a fixed one. Reserving the space stops the
    // controls walking up and down the screen every time the recogniser
    // changes its mind; fixing it would clip the text at any accessibility
    // font scale above about 1.3.
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: context.spacing.spacing3Xl),
      child: Center(
        child: AppText(
          title: text,
          maxLines: lines,
          textAlign: TextAlign.center,
          style: context.typography.textMd.regular.copyWith(color: color),
        ),
      ),
    );
  }
}

/// A quiet, tappable line of text — a choice, not an action.
class const _TextButton({
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
        padding: EdgeInsets.symmetric(vertical: context.spacing.spacingSm),
        child: AppText(
          title: title,
          textAlign: TextAlign.center,
          style: context.typography.textSm.medium.copyWith(
            color: context.textColors.textBrand,
          ),
        ),
      ),
    ),
  );
}

class const _Centered({required final String text}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: AppText(
      title: text,
      style: context.typography.textMd.regular.copyWith(
        color: context.textColors.textTertiary,
      ),
    ),
  );
}
