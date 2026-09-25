# Circular Words — Build Plan

A voice-driven English vocabulary game. The player picks a CEFR level, then
works around a circle of 26 letters: each letter shows a definition, and the
player **speaks** the word that matches it and begins with that letter.

This document is the build plan — the settled decisions and the order the work
happens in. When a decision here stops matching the code, change this file in
the same commit.

---

## 1. Game rules

The format is Pasapalabra's *rosco*, adapted for language learning.

| Rule | Value |
| ---- | ----- |
| Letters per round | 26 (A–Z) |
| Total time | **260 s, a shared pool** |
| Per-letter cap | **10 s, a soft cap** |
| Passing | Allowed; a passed letter is requeued for a later lap |
| Wrong answer | Never ends the round — the player plays on |
| Alphabet | **Always A–Z.** No relaxed pool for rare letters |
| Round ends | Pool hits 0, or all 26 letters are terminal |
| Levels | CEFR **A1, A2, B1, B2, C1, C2** |

### The pool is the only clock

260 s is a **pool**, not the sum of 26 independent 10 s timers. Answering a
letter in 3 s leaves the other 7 s in the pool for later letters; that banked
time is what makes a second lap possible, and it is what makes the circle mean
something rather than being decoration.

This has one consequence that must be honoured in the state shape:

> **The per-letter countdown is derived, never stored.**
>
> ```dart
> int get letterRemaining =>
>     max(0, min(kLetterCapSeconds - spentOnCurrentLetter, remainingPool));
> ```
>
> Storing both clocks independently lets them drift, and the failure is
> specific and ugly: on the last letter the per-letter timer offers 10 s that
> the pool cannot pay for. One source of truth — `remainingPool` — with the
> letter countdown computed from it.
>
> An earlier draft of this plan wrote
> `min(kLetterCap, remainingPool - spentOnCurrentLetter)`, which is wrong: the
> pool is already decremented every tick, so subtracting the letter's spend
> from it again double-counts and the letter shows a full 10 s no matter how
> long it has been open. The cap is what `spentOnCurrentLetter` reduces; the
> pool is what caps *that*.

A literal reading of "10 s per letter, 260 s total" gives exactly one lap with
no room to revisit anything (26 × 10 = 260). That reading was considered and
rejected in favour of the pool.

### Nothing ends the round early

A wrong answer costs time, never the round. The player keeps going, and the
round runs until the pool is empty or there is genuinely nothing left to
answer. An unproductive lap — a full circle with nothing answered — does **not**
end it either.

Concretely, the round ends on exactly two conditions:

1. `remainingPool == 0`, or
2. every letter is terminal (`correct` or `wrong`).

`passed` is deliberately **not** terminal, which is what keeps a second lap
reachable.

### Letter lifecycle

```
pending ──▶ active ──┬──▶ correct              (accepted answer)
                     ├──▶ wrong                (10 s cap expired)
                     └──▶ passed ──▶ (requeued) ──▶ active ...
```

A rejected answer does not resolve the letter. The letter stays `active` and
the player may try again inside its remaining seconds; it becomes `wrong` only
when the 10 s cap expires. The cost of a bad guess is the time it burned out of
the shared pool — which is a real cost, since that time is gone for every
letter after it.

> **This is a judgment call, not something the requirement settled.** "Continue
> even if you failed some words" fixes that failures never end the *round*; it
> leaves open whether a rejected answer burns the *letter*. Retry is the
> forgiving reading, and speech recognition makes it close to necessary — a
> single misheard syllable should not cost a letter the player actually knew.
> Say the word and it becomes one-shot instead.

### Always A–Z

Every round walks the full alphabet. Rare letters are not swapped out, and
there is no "contains the letter" relaxation for X and Z the way televised
Pasapalabra allows.

> **This lands entirely on the word bank, and it bites hardest at A1.** English
> has almost no beginner-level words starting with X — realistically `x-ray`
> and little else — so the X entry (and to a lesser degree Z) will repeat
> across sets at the lower levels. That is accepted: the alternative is
> breaking the alphabet. Revisit only if playtesting shows X is the letter
> everyone passes.

---

## 2. Where this came from

Generated from
[`modular_app_template`](https://github.com/Yusubov-Engineering/modular_app_template),
then renamed and stripped of its `counter` and `posts` demo features. The
architecture — package-per-capability, `_api`/`_impl`, DI modules, module
routers, `state_manager` — is inherited wholesale and is documented in
[CLAUDE.md](CLAUDE.md).

Once generated, this project no longer receives template fixes. That is the
accepted trade-off.

---

## 3. Package map

| Package | Status | Holds |
| ------- | ------ | ----- |
| `speech_api` ([own repo](https://github.com/Yusubov-Engineering/speech), `v1.0.0`) | built | `SpeechRecognizerApi`, sealed `SpeechAvailability`, `SpeechResult` |
| `speech_impl` ([own repo](https://github.com/Yusubov-Engineering/speech), `v1.0.0`) | built | `speech_to_text` ^7.3.0 wrapper, `SpeechModule` |
| `features/levels/levels_{api,impl}` | built | level picker, best scores, entry route |
| `features/rosco/rosco_{api,impl}` | in progress | `CefrLevel`, `LevelScore`, `RoscoScoreboard`, `/rosco/:level`; the round itself is milestones 5–7 |

### Why speech is a core module, not part of the game

Speech recognition is infrastructure, not domain. It gets the same `_api`/`_impl`
split every other core capability has, so the game feature depends on an
interface it can fake in tests and never on a platform plugin. It lived
in-tree as a workspace member until it had proven itself on hardware
(milestones 2 and 9); it now lives in `Yusubov-Engineering/speech` like the
other core modules, pulled in as a `git:` dependency pinned to `v1.0.0`.
Changing it means a new tag there and a `ref:` bump in `app` and `rosco_impl`.

### `CefrLevel` lives in `rosco_api`, not `levels_api`

The dependency runs *levels → rosco*: the picker asks the game's launcher for
a route, so the launcher's parameter type must be visible to the caller.
Defining the level in `levels_api` would force `rosco` to depend on `levels`
and close the loop.

For the same reason `RoscoScoreboard` belongs to `rosco` — the module that
*produces* a score — and `levels` reads it through `RoscoApi`. One writer, and
`levels` knows nothing about how a score is stored.

### Why two features rather than one

`levels` → `rosco` is exactly the cross-module case the template is built
around. `levels_impl` depends on `rosco_api`, resolves it with
`context.locator<RoscoApi>()`, and asks the launcher for a request:

```dart
final rosco = context.locator<RoscoApi>();
context.navigation.pushRoute(rosco.launcher.game(level: level));
```

`levels_impl` never imports `rosco_impl` and never names a path belonging to
`rosco`.

---

## 4. Routes

```
/levels                  LevelsScreen     ← initial location
/rosco/:level            RoscoScreen
/rosco/:level/result     ResultScreen     ← nested under the game
```

Addresses stay private to each `_impl` in `<Feature>RouteInfo` and are never
exported from the barrel.

---

## 5. Speech pipeline

[`speech_to_text`](https://pub.dev/packages/speech_to_text), which wraps
`SFSpeechRecognizer` on iOS and `SpeechRecognizer` on Android.

### Platform setup

- **iOS** — `NSMicrophoneUsageDescription` and `NSSpeechRecognitionUsageDescription`
  in `app/ios/Runner/Info.plist`. There is **one** plist, not one per flavor:
  the flavors differ by build setting (`APP_DISPLAY_NAME`,
  `PRODUCT_BUNDLE_IDENTIFIER`), which the plist interpolates.
- **Android** — `RECORD_AUDIO`, plus **two** `<queries>` intents:
  `android.speech.RecognitionService` for the bound service the plugin uses,
  and `android.speech.action.RECOGNIZE_SPEECH` for the intent-based path.
  Without them Android 11+ hides the recogniser and the plugin reports "no
  recognizer" on a device that has one.

### Listening strategy

- **One listen session per minute**, not one per letter — and never torn down
  because a letter changed. Restarting per letter cost 26 teardowns a round,
  each an audible tone and a gap with no microphone, and the gap falls exactly
  where a player speaks: right after a new clue. The length is measured, not
  chosen; see `kMicSessionSeconds`, and the table in
  [§5](#the-session-length-is-measured-and-not-monotonic).
- **Score partial results, not just finals.** This is not an optimisation — it
  is the difference between a playable game and an unplayable one. See the
  measurements below.
- **Validate against every alternate.** `speech_to_text` returns ranked
  alternates and the top one is often not the best one.

### Measured on device — Samsung S25 Ultra, Android 16 (API 36)

Milestone 2's probe, saying "abundant" twice:

```
partial +2797ms  "abundant"  alts=[albondant, album dumped, album dump, abundantump]
FINAL   +7801ms  "abundant"  alts=[albondant, album dumped, album dump, abundantump]

partial +3413ms  "abundant"  alts=[up on that, Ubuntu, abundant out, upon dunk, upon dunked]
FINAL   +7591ms  "abundant"  alts=[up on that, Ubuntu, abundant out, upon dunk, upon dunked]
```

Three facts to design against, all of them larger than estimated:

1. **The final arrives ~5 s after the partial that already contained the
   answer** — around 7.6–7.8 s into a 10 s letter. Waiting for finals would
   consume three quarters of the budget per letter and make a second lap
   arithmetically impossible. Partials are mandatory.
2. **The transcript and its alternates are identical between partial and
   final.** There is no accuracy gained by waiting, only latency.
3. **Alternates are noisy** — `Ubuntu`, `album dumped` — but cost nothing to
   check, and the fuzzy rules in [§6](#6-answer-validation) are what turn
   `albondant` into an accepted answer.

#### A silent letter ends its microphone session early

Saying nothing closed the session after **5.5 s**, not at the 10 s cap:
`pauseFor` (3 s) elapses, Android reports `NO_SPEECH_DETECTED`, and the grace
period closes the stream 2.5 s later.

> **Consequence for milestone 7.** A player who pauses to think must not lose
> the microphone. Two things follow, and only the second was obvious at the
> time: **re-open a session whenever one closes while the round is still
> running**, and — the real fix — **stop causing the closures**. `pauseFor` is
> what shuts the microphone on a silent player, so it is sized to the round.
> A letter ends when the *round's* clock says so, never when the recogniser
> gives up, and the recogniser is now given no reason to.

### How milestone 7 answered it

`MicController` owns the microphone for the length of a round, and owns
nothing else. The round's rules never learn that speech exists; the
microphone never learns what a letter is. They meet at one seam — the mic
provider's `onEffect`, which turns a transcript into a `RoscoAnswered` event —
and that seam is why a whole round is still playable in a unit test with no
plugin at all.

Three decisions came out of the measurements above:

- **A session is not a letter, and a letter must not end a session.** A letter
  changing leaves a working session alone; only one that has actually ended is
  replaced. Confirmed on device: nine words in a row through one microphone,
  a clean rollover, then nine more — opened twice in eighty seconds, where the
  per-letter design opened it fifteen times in forty-five.
- **Restarting is bounded.** Six sessions per prompt. Real play needs two or
  three; a platform that closes every session as it opens would otherwise spin
  for the whole round.
- **Partials are scored, not rejected.** `RoscoAnswered.tentative` carries the
  difference. A partial that holds the answer wins the letter immediately; one
  that does not is simply a word still being said, so nothing is shown and
  nothing buzzes.

### The session length is measured, and not monotonic

How long one listening session runs is the single most consequential number in
the speech path, and the obvious reasoning about it — *longer is better, so
make it the round* — is wrong. Measured on a Samsung S25 Ultra, speaking ten
to twenty words into a live round:

| `pauseFor` | words heard | microphone opened |
| ---------- | ----------- | ----------------- |
| 3 s | — | every 3 s, and shut most of the time |
| 10 s | good | every 10 s |
| **60 s** | **9/10, then 9 more after the rollover** | **twice in 80 s** |
| 260 s (the round) | 2/10 | once |

The collapse at the end is not a scaling problem, it is a cliff. A
round-length silence window puts Google's recogniser into a continuous mode
that `speech_to_text` does not forward: `_notifyResults` returns early for
everything once a session has produced one final result, so the platform went
on detecting utterances — 24 of them, against 13 results — that never reached
the app. The microphone was open, the tone never sounded, and the game could
not hear a word.

**A minute is comfortably inside the working range**, and costs one rollover a
minute. The remaining loss is a word spoken during that rollover; the
alternative — a session per letter — loses far more, and beeps while doing it.

### What the device taught us, after it was wired in

Milestone 7 worked in tests and failed on hardware, four times over, each
failure hiding behind the one in front of it. All four came from the same
mistaken assumption — that the plugin's callbacks describe *a session*. They
describe *the plugin*, and they arrive late.

1. **`pauseFor` is not a pause, it is the window.** Android applies the
   silence timeout as the whole listening period: a 3 s `pauseFor` shut the
   microphone 3.0 s after opening it, every time, whether or not anyone was
   speaking. Sized to the letter, one session covers one letter — measured at
   exactly 10.0 s apart.
2. **Every Android error is reported `permanent: true`.** The plugin writes
   that flag as a constant, so `error.permanent` decides nothing there. Which
   errors are survivable has to be decided in code: `kBenignSpeechErrors`.
3. **`error_client` means "still busy", not "no recogniser".** Answering a
   letter advanced the round, the next session raced the previous one's
   teardown, and Android answered with `error_client` — which was read as
   *this device cannot do speech recognition*. **One correct answer disabled
   the microphone for the rest of the round.** This was the bug that made the
   game unplayable, and it was invisible until a word was actually spoken.
4. **Waiting for a final costs more than the final is worth.** Holding each
   stream open 2.5 s for the plugin's synthesised final left the microphone
   shut for 2.7 s of every 3 s of silence — so a player who paused to think
   and then spoke was, more often than not, speaking into a closed
   microphone. The finals were never worth it: they carry the same transcript
   and the same alternates as a partial five seconds earlier.

The fix for (4) is the one worth remembering, because it is a design change
rather than a constant. **The caller settles the utterance, not the
platform.** Everything heard while a session is open is tentative; when the
session ends, whatever was last heard is what the player said. No better
version is coming. That removed the last dependence on platform finals and
with it the last magic number.

### Failure paths — designed, not discovered

Permission denied, no recognizer installed, and offline are all normal states,
not errors. `initialize()` returns a sealed `SpeechAvailability` rather than
throwing, so every caller switches exhaustively and each case resolves to the
same place: the **text-input fallback**.

Two distinctions the implementation turns on:

- **Transient errors are not failures.** `error_no_match` and
  `error_speech_timeout` arrive constantly during normal play — a player who
  thinks for eight seconds produces one. `kBenignSpeechErrors` keeps them from
  tearing down a session that is working. Only permanent errors end it.
- **The module registers the recogniser but never initialises it.** Calling
  `initialize()` prompts for the microphone, and app start — before the player
  has chosen to play anything — is the wrong moment to ask. The game screen
  initialises on entry.

---

## 6. Answer validation

Pure Dart in `rosco_impl/lib/src/domain/`. No plugin, no `BuildContext`, so it
is fully unit-testable — and this is where most of the test suite belongs.

`AnswerValidator.validate(spoken, target)` accepts when:

**Authored answers are trusted; inferred ones must fit the letter.**

- **Authored** — the entry's `word` and its `synonyms`, matched after
  normalising (lowercase, diacritics folded, punctuation and spacing removed,
  leading articles stripped). Accepted as written, because whoever authored the
  clue is the authority on what answers it. This is what lets `x-ray` accept
  the recogniser's "ex ray", and what lets a set accept a near-synonym its
  author chose to allow.
- **Inferred** — a fuzzy or homophone match the validator worked out itself:
  Levenshtein ≤ 1 for targets of 5+ characters, ≤ 2 for 8+, plus a small
  curated homophone map. These **must still begin with the letter in play**,
  so that tolerance for a misheard syllable never becomes acceptance of a
  different word.

Every candidate is tried both as the whole utterance and word by word, because
recognisers return "the abundant" and "um abundant".

> The letter guard only binds the inferred path, and that is deliberate. If
> "plentiful" should not answer an A, the fix is to remove it from the asset —
> the decision belongs in the content, not in the engine.

> Exact string equality will feel broken to a real player. An English learner's
> pronunciation is precisely what speech recognition handles worst, so the
> tolerance above is a correctness requirement, not a nicety.

---

## 7. Word bank

Bundled JSON assets, one file per level, holding every set for that level:
`rosco_impl/assets/words/a1.json` … `c2.json`.

```json
{
  "level": "b1",
  "sets": [
    {
      "id": "b1-1",
      "entries": [
        {
          "letter": "A",
          "word": "abundant",
          "definition": "Existing in large quantities; more than enough.",
          "synonyms": ["plentiful"]
        }
      ]
    }
  ]
}
```

Assets belong to `rosco_impl` and are read at
`packages/rosco_impl/assets/words/<level>.json` — the `packages/` prefix is how
a package addresses its own assets through the root bundle. Without it the path
resolves against the *app's* assets, parses perfectly in every unit test, and
fails only on a device, which is why
`test/word_bank_real_assets_test.dart` loads the real files through the real
bundle at the production path.

Several sets per level, so a replay is not identical.

**Every set must be complete A–Z**, because the alphabet is never relaxed. A
set with a missing letter is a corrupt set, not a shorter round — the loader
rejects it as `RoscoWordBankMalformed` rather than starting a 25-letter game.

`test/word_bank_assets_test.dart` guards every shipped asset: 26 distinct
letters, each word filed under its own initial, and **no definition containing
its own answer** — a clue that gives away the word is not a clue. Cheap tests,
and the only thing standing between a typo and an unplayable level.

**All six levels are authored, five sets each — 780 entries.** An unauthored
level is no longer reachable through the picker, but a *missing asset* still
resolves to `RoscoLevelUnavailable` and stays covered by a test against an
empty bundle.

Offline, deterministic, no API key, no rate limit. The repository follows the
shape the template's `posts` feature demonstrates — data source → repository →
sealed failure — so moving to a remote source later touches one file.

### How the content gets written

> The original plan called this "the real cost of the project" — six levels ×
> 26 letters × N sets of hand-authoring. That framing was right about the cost
> and wrong about who pays it.

Content is **authored by Claude and shipped bundled**, via
`tool/word_bank_authoring/`. The distinction that makes this safe is *when* the
model runs: at authoring time, on a developer's machine, with the output
reviewed and committed like any other source file. The app never calls an API,
never holds a key, and works offline exactly as before.

Alternatives considered and rejected:

- **A public dictionary API** cannot grade by CEFR. Definitions come back
  circular, technical, or containing the target word, and the A1/B1 distinction
  is the product. It would also make the "no definition contains its answer"
  guarantee unenforceable, since it could only be checked after fetching.
- **Runtime generation** would need a proxy to hold the key, a network round
  trip before every round, and validation of each set before play — trading
  away offline play and determinism for variety the bundled form can get by
  shipping more sets.
- **A remote word-bank API** doesn't write a single definition. It relocates
  the same hand-authored content and costs offline play.

Two layers of checking, at different moments:

| Where | When | Catches |
| ----- | ---- | ------- |
| `tool/word_bank_authoring/word_bank_gates.py` | before anything is written | a generator producing a bad set |
| `rosco_impl/test/word_bank_assets_test.dart` | CI, against committed assets | a bad set surviving, however it got there |

Neither can judge whether a word belongs at its level or teaches well. That is
a human read, and it stays a human read — the gates exist to make it short.

---

## 8. State

`RoscoController extends AppStateController<RoscoState, RoscoEvent, RoscoEffect>`.

**State** — `List<LetterSlot>` (letter, word, definition, and a
`LetterStatus` of `pending` / `active` / `correct` / `wrong` / `passed`),
`currentIndex`, `remainingPool`, `spentOnCurrentLetter`, `lap`, `passedQueue`,
`micState`, `lastTranscript`.

**Events** — `RoscoTicked`, `RoscoAnswered(answer)`, `RoscoPassed`,
`RoscoRetried`. Speech arrives as `RoscoAnswered` like any other answer, so
milestone 7 adds a source, not a code path.

**Effects** — `RoscoAccepted`, `RoscoRejected`, `RoscoFinished(score)`.

The clock is a `TickSource` — `Stream<void> Function()` — injected rather than
constructed, so a whole round plays out in a unit test in milliseconds instead
of 260 seconds.

**A rejected answer is not a state transition.** `AnswerSubmitted` with a
non-matching word leaves `LetterStatus.active` exactly where it was; it emits
feedback (`PlaySound`, `Haptic`), updates `lastTranscript`, and lets the clock
keep running. Only two things resolve a letter: an accepted answer
(`correct`), or the 10 s cap expiring (`wrong`). `Passed` defers it without
resolving it.

This is worth stating in the state machine because it is the rule most likely
to be broken by accident — the obvious implementation of "handle a wrong
answer" advances the letter, and that is precisely what must not happen.

Two lifecycle rules, both inherited from the template and both easy to get
wrong here:

- The `Timer.periodic(1s)` and the speech `StreamSubscription` start in
  `onInit` and are **both cancelled in an overridden `dispose()`**. A game
  screen leaks more visibly than most.
- **Navigation is an effect.** The controller never touches `BuildContext`,
  which is what keeps it testable with a fake recogniser.

`Ticked` is also the only place the round can end, and it checks both
conditions from [§1](#nothing-ends-the-round-early): the pool reaching 0, and
every letter having become terminal. Ending anywhere else — on the last letter
of a lap, on a wrong answer — reintroduces exactly the early exit the rules
rule out.

---

## 9. Design system additions

- `AppStatusColorTokens` in `core/design_system` — `statusSuccess`,
  `statusWarning`, `statusDanger`, `statusInfo`, `statusNeutral` and
  `statusOnFill`, defined in **both** the `light()` and `dark()` factories.
  Named for meaning rather than for the game: the wheel maps
  correct → success, wrong → danger, passed → warning, active → info,
  pending → neutral, so the family does not grow one entry per feature.
  Backed by new `success` and `warning` ramps in `AppColorPalette`.
- `AppText` gained `textAlign`.
- `RoscoWheel` (in `rosco_impl`, not the design system — it is this game's
  shape, not a reusable component) — one `CustomPaint` drawing the timer ring,
  26 letter chips positioned by angle, and the countdown in the middle. The
  geometry is two pure functions, `roscoLetterOffset` and `roscoChipRadius`,
  so the wheel is testable without pixels.
- `MicButton` — **deferred to milestone 7**, where the recogniser gives it
  something to do. Shipping a button that does nothing is worse than shipping
  it one milestone later.

Use tokens throughout — `context.spacing.spacingXl`, never `16.0`.

---

## 10. Localization and persistence

- UI chrome is localized across all seven inherited locales
  (en, ar, az, es, ru, tr, zh). **Word definitions stay English** — the English
  is the subject being taught, not the interface.
- Best score and best time per level persist through `StandardStorageApi` and
  surface on the level cards.

---

## 11. Milestones

| # | Milestone | Done when |
| - | --------- | --------- |
| 1 | **Scaffold** ✅ | Renamed, demos stripped, `levels` + `rosco` generated; `flutter analyze`, `modular doctor`, `melos test` all green |
| 2 | **`speech` core module** ✅ | `_api`/`_impl` built, wired, permissions declared, and transcription proven on a Samsung S25 Ultra — partials, finals, alternates, silence handling and back-to-back sessions all verified |
| 3 | **Levels feature** ✅ | Picker screen, `CefrLevel`, `RoscoScoreboard` over storage, cross-module launcher navigation — verified on device (`/rosco/b1` reached from a tap) |
| 4 | **Word bank** ✅ | Schema, A1 + B1 authored (2 sets each), asset data source, repository, sealed `RoscoFailure` — verified on device: A1 loads 26 letters from the APK, A2 shows the unavailable message |
| 5 | **Rosco engine** ✅ | State machine, `AnswerValidator`, injected clock; 36 unit tests with no microphone and no widget tree, plus a text-input harness verified on device |
| 6 | **Rosco UI** ✅ | Wheel, timer ring, status tokens, cross-fade transitions; 11 geometry tests, and all five letter states verified on device. Mic button moved to 7 |
| 7 | **Speech wired in** ✅ | `MicController` + mic button; one session held across the round, utterances settled by the caller, keyboard fallback one tap away. 24 mic tests against a fake recogniser, and on device **12 letters answered by voice on a single microphone session** |
| 8 | **Result + persistence** ✅ | Result screen at `/rosco/:level/result`, the score carried in the query string and written there; play-again and back-to-picker both verified on device, with the best score surviving to the level card |
| 9 | **Polish** ✅ | `feedback` core module (generated sounds + haptics, mutable), semantics across every control, and the text scaler unpinned. Verified on a Samsung S25 Ultra: `SoundPool` registered by the app, haptics firing `constant=3` on each correct answer and `constant=4` on each timeout, the accessibility tree reading the wheel aloud, and 1.5× text with no overflow on any screen |

**Milestone 5 lands before 6 and 7 deliberately.** The pool arithmetic, the
pass queue and the lap logic are where the bugs will be, and all of it is
testable without a microphone or a widget tree. Building the wheel first would
mean debugging the state machine through an animation.

---

### Where a score is written, and why not in the round

`ResultController` records, not `RoscoController`. The round is a rules engine
with no `BuildContext`, no plugin and no storage, and that is what lets a whole
260-second round play out in a unit test in milliseconds. Handing it a
scoreboard would buy nothing and cost that.

The trade is a few milliseconds of exposure: an app killed between the last
letter and the result screen loses the round. For a word game that is the right
side of the trade — and it is not hypothetical, since a debug build idling on a
Samsung gets killed regularly, which is exactly how it was observed.

Recording is idempotent by construction. `record` only writes a score that
beats what is stored, so reopening the result screen — or a link to it — cannot
inflate anything.

---

## 11a. Feedback, and why it is a core module

Sound and haptics live in `core/feedback`, behind `GameFeedbackApi`, for the
same reason speech does: `audioplayers` is a plugin, and nothing under
`features/` may import one. The game asks for a *meaning* — `correct()`,
`rejected()`, `wrong()`, `finished()` — and the module decides how to deliver
it.

Three decisions worth keeping:

- **Every cue is two channels, and muting covers only one.** A phone on silent
  still taps; a phone with haptics off still chimes. They are not the same
  message sent twice, they are the same message sent to whichever sense is
  available — so the mute toggle silences sound and leaves haptics to the
  system's own setting.
- **A rejection is felt but never heard.** With speech, a rejection is usually
  a mishearing rather than a mistake, and it happens several times a letter.
  Chiming at each one would make the game tiring to play badly, which is how a
  learner starts.
- **Feedback never throws at its caller.** A cue is a comment on something that
  already happened; a missing codec or an absent vibrator must not take down
  the round it was commenting on. Every call is wrapped, and the swallowing is
  deliberate rather than lazy.

The sounds are **generated, not sourced** —
`tool/sound_authoring/generate_sounds.py` writes three enveloped sine chords,
about 70 KB in total. Correct rises, wrong falls, and wrong is quieter and
shorter than correct.

## 11b. Accessibility

The app had no `Semantics` at all before this milestone: every control was a
bare `GestureDetector`, which a screen reader announces as loose text with no
hint that it does anything. Now:

- `AppPrimaryButton` carries `button`/`enabled`/`label` — one fix in the design
  system covering every button in the app.
- The **wheel** is a `CustomPaint`, and so was a blank rectangle to assistive
  technology despite being the entire subject of the screen. It now announces
  the letter, the clock and the score.
- The **clue is a live region**, because it is the one thing that changes
  without the player touching anything.
- The mic button announces its **toggled** state, and the sound toggle draws a
  cross rather than relying on colour alone.
- Text containers that reserve space use a **minimum** height, not a fixed one.
  A fixed box clips its own text somewhere above a 1.3 font scale, and the two
  worst offenders were both mine. A long clue scrolls rather than truncating —
  a truncated clue is an unanswerable letter.

---

## 11c. What testing on hardware found

Every one of these was invisible in tests and on a first glance at the app, and
each was found by doing the boring thing on a device.

- **The app ignored the system font size.** `app/lib/app.dart` passed the same
  value as `minScaleFactor` and `maxScaleFactor`, which pins the text scaler:
  at Android's largest font setting the app rendered exactly as at the
  smallest. Inherited from the template, and it made every other accessibility
  fix here unreachable. Now bounded at 1.5× rather than pinned — **worth a
  second opinion**, since it changes text size on every screen and the pin may
  have been a deliberate fidelity choice.
- **A denied microphone could never be reported as denied.** `initialize()`
  declared a `failure` variable, never assigned it, and then read it — so every
  failure said "this device has no speech recognition", including a player
  tapping *Don't allow*. Dead code from milestone 2, reachable only by actually
  denying the permission.
- **The give-up state contradicted itself.** When the restart budget ran out
  the microphone set `status: idle` but left `enabled: true`. The button is
  drawn from the status, so it read as off; its tap handler read `enabled`, so
  the tap switched off a microphone that had already stopped. Two taps to
  recover, the first appearing to do nothing. `enabled` and `status` now move
  together, and a new letter revives a microphone that gave up — while one the
  *player* switched off stays off.
- **The mute preference was stored correctly and displayed wrongly.**
  `initialize()` read the preference and then awaited three audio decodes
  before returning, so the toggle came up showing "on" for a player who had
  muted the game. Decoding is a warm-up and no longer blocks the answer.

---

## 12. Risks

| Risk | Mitigation |
| ---- | ---------- |
| **Learner accents are what STT handles worst** — the core product risk | Generous fuzzy thresholds, explicit `localeId`, text fallback always reachable |
| **iOS Simulator cannot do speech recognition reliably** | Milestone 2 requires a physical device; CI can never cover the speech path |
| **Android recognizer availability varies by OEM** | Detect at startup via `available()`, degrade to text input |
| **Recognition latency eats the 10 s budget** | Score partial results rather than waiting for finals |
| **No template fixes flow here after generation** | Accepted; port deliberately if it matters |

---

## 13. Decisions log

Questions that were open, and how they were settled. Kept so that a rule which
looks arbitrary later can be traced to the reasoning that produced it.

| Question | Settled as | Where it lives |
| -------- | ---------- | -------------- |
| 10 s per letter vs. 260 s total | **Pool.** 260 s shared; 10 s is a soft cap; unused time banks | [§1](#the-pool-is-the-only-clock) |
| Levels | **CEFR A1–C2**, six levels | [§1](#1-game-rules) |
| One feature or two | **Two** — `levels` and `rosco`, joined by the launcher | [§3](#why-two-features-rather-than-one) |
| Voice-only or a fallback | **Text fallback ships**, and doubles as the test harness | [§5](#failure-paths--designed-not-discovered) |
| Does a failure end the round | **No.** The player plays on | [§1](#nothing-ends-the-round-early) |
| Rare letters (X, Z) | **Always A–Z.** No relaxed pool | [§1](#always-az) |
| Unproductive lap | **Run the pool down.** Only an empty pool or an all-terminal board ends it | [§1](#nothing-ends-the-round-early) |
| Word-bank size | **Five sets per level, as a floor** (780 entries). CI fails below five and on any word repeated across a level's sets | `rosco_impl/test/word_bank_assets_test.dart` |
| Speech in-tree or its own repo | **Own repo** (`Yusubov-Engineering/speech`), once proven on hardware | [§3](#why-speech-is-a-core-module-not-part-of-the-game) |
| What colour means | **Accents say where, status says what.** Each CEFR level has a hue (`CefrLevel.accent`) that tints its card, its round and its result; success/danger/warning keep one meaning everywhere | `rosco_api/lib/src/cefr_level_accent.dart` |
| How much motion | **Lively but calm.** Press feedback, a gliding highlight, a pop on each decided letter, a count-up on the score; nothing loops but the listening pulse, and all of it yields to the OS reduce-motion setting | `core/design_system/lib/src/tokens/motion/` |
| Page transitions | **Fade-through, set once** as the router's default (router `v1.1.0` added `CustomPresentationMode`); the three screens are not spatially related, so a slide would imply a direction that does not exist | `app/lib/bootstrap/router_configuration.dart` |
| Landscape | **Rearrange, don't lock.** Rotation stays allowed; each screen has a landscape arrangement chosen by `AppAdaptiveLayout` from its own constraints — the wheel beside the controls rather than above them, levels in two columns, score beside actions | `core/design_system/lib/src/layouts/app_adaptive_layout.dart` |

One sub-question is settled by judgment rather than by requirement, and is the
one to overrule first if the game feels wrong:

- **A rejected answer does not burn the letter** — the player may retry inside
  the letter's remaining seconds, and `wrong` means "the 10 s expired". See
  [§1](#letter-lifecycle). Speech recognition is unreliable enough that
  one-shot answering punishes recognition failures as if they were vocabulary
  failures.
