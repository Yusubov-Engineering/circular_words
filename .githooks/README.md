# Git hooks

Local mirrors of the GitHub Actions `verify` workflow, so you find formatting and analysis
problems in seconds on your own machine instead of minutes later in a pipeline.

| Hook | Runs | Checks | Typical cost |
| ---- | ---- | ------ | ------------ |
| `pre-commit` | `git commit` | `dart format` on **staged** `.dart` files only | well under a second |
| `pre-push` | `git push` | `dart format` across the repo, then `flutter analyze` | ~6 seconds |

They are a convenience, not the gate. CI remains authoritative — anyone can bypass a
hook, and a fresh clone has them switched off until someone runs the setup command below.

---

## Setup

**Once per clone**, from the repo root:

```bash
git config core.hooksPath .githooks
```

That is the whole install. There is nothing to download — the hooks are plain bash,
committed to the repo, and this points git at them instead of the unversioned
`.git/hooks/`.

It is deliberately not automatic. Git will not run hooks a clone did not opt into, and
that is a good thing: nothing this repo ships should execute on your machine without you
asking for it.

### Verify it took

```bash
git config --get core.hooksPath      # → .githooks
```

Then try it for real:

```bash
printf 'void _probe(  ) {   }\n' > lib_probe.dart
git add lib_probe.dart
git commit -m "should be blocked"
```

You should see:

```
✖ pre-commit: staged Dart files are not formatted:

    lib_probe.dart

  Fix:   dart format .
         git add -u
  Skip:  git commit --no-verify
```

Clean up with `git reset lib_probe.dart && rm lib_probe.dart`.

### Turning it off

```bash
git config --unset core.hooksPath
```

---

## Skipping a check

Both hooks honour git's standard escape hatch:

```bash
git commit --no-verify
git push --no-verify
```

`SKIP_HOOKS=1` does the same and is easier to export for a whole shell session:

```bash
SKIP_HOOKS=1 git push
```

Use it for work-in-progress commits on your own branch. Skipping does not help you at the
end — CI runs the same checks, and merge requests cannot merge on a red pipeline.

---

## Why two hooks instead of one

`flutter analyze` takes a few seconds and needs the whole workspace resolved. Running it
on every commit would make committing feel slow enough that people start reaching for
`--no-verify` out of habit, which defeats the point. So the split is:

- **`pre-commit` is the fast one.** It formats only the files you staged, so it stays under
  a second no matter how large the repo grows.
- **`pre-push` is the thorough one.** It runs exactly what CI runs, over everything, right
  before code leaves your machine — the last moment where catching a problem is still free.

`pre-push` runs both checks even when the first fails, so one push tells you everything
that is wrong rather than making you discover problems one at a time.

---

## A limitation worth knowing

`pre-commit` checks the files as they exist in your **working tree**, not the exact content
you staged. Those are almost always the same. They differ if you stage a formatted version
of a file and then edit it again without staging, or if you stage part of a file with
`git add -p`. In that case the hook may complain about something that is not in your
commit.

Fixing this properly means checking out staged content to a temporary location, which
breaks the package resolution `dart format` depends on (see below). The trade is
deliberate: `pre-push` catches whatever `pre-commit` gets wrong, and it checks real files
at real paths.

---

## Troubleshooting

| Symptom | Cause |
| ------- | ----- |
| Hooks never run | `core.hooksPath` was not set in this clone. It is per-clone, not per-machine, and does not survive a re-clone |
| `'dart' is not on PATH — skipping` | Flutter is not on your `PATH` in a non-interactive shell. GUI git clients are the usual culprit — they do not read your `.zshrc` |
| Hook is not executable | The executable bit is committed, so this should not happen. If it does: `chmod +x .githooks/*` |
| `pre-commit` flags a file you did not change | See the limitation above — check your working tree, or run `dart format .` |
| Formatting differs from a colleague's | Someone is on a different Flutter version. The repo pins `flutter: 3.47.0` in the root `pubspec.yaml`, and the formatter's output depends on it |
| You use fvm | Use `fvm flutter` / `fvm dart`, or make sure `.fvm/flutter_sdk/bin` comes first on `PATH` |

---

## Why formatting needs resolved packages

Both hooks run `dart format` against real paths inside the repo, never against copies.
`dart format` picks its line-splitting style from each package's **language version**,
which it reads from `.dart_tool/package_config.json`. In this workspace those versions
differ per package — `router_impl` declares `sdk: ^3.11.5` while most declare `^3.13.0` —
so the same file formats differently depending on where it sits.

This is not theoretical: it is exactly what broke the CI `format` job before `flutter pub
get` was added to it. If you ever extend these hooks, keep the files in place.
