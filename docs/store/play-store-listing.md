# Google Play — store listing and forms

Everything to paste into the Play Console for the first release. Keep this
file in step with the app: when a feature or a data flow changes, update the
listing and the Data safety answers in the same commit.

## Main store listing

**App name** (30 max)

> Circular Words

**Short description** (80 max)

> Say the word! A voice vocabulary game for English learners, from A1 to C2.

**Full description** (4000 max)

> Learn English words by saying them out loud.
>
> Circular Words is a fast, friendly vocabulary game built around a circle of
> 26 letters. Every letter hides a word: read its definition, then say the
> word that starts with that letter. Get it right and the letter turns green.
> Not sure? Pass — it comes back on the next lap.
>
> **Play at your level**
> Six CEFR levels, from Beginner (A1) to Proficient (C2), each with its own
> sets of words — 780 in all. Start where you are and climb.
>
> **Just speak**
> No typing needed: the game listens and checks your answer as you say it.
> Prefer to type, or somewhere quiet? Switch to the keyboard at any time.
>
> **Beat the clock**
> 260 seconds for the whole circle, and up to ten seconds for each letter.
> Answer, pass, and come back — the round ends when the clock runs out or
> every letter is green.
>
> **Learn from what you missed**
> After each round you see every word you missed, with its definition, so the
> next round goes better.
>
> **Share your circle**
> Turn your score into an image and share it with friends.
>
> **Made for learners**
> • 6 levels, A1 to C2
> • 780 words with clear, simple definitions
> • Voice or keyboard answers
> • Best score saved for every level
> • Interface in English, Arabic, Azerbaijani, Chinese, Russian, Spanish and
>   Turkish
> • Light and dark themes, landscape and portrait
> • No account, no ads

**Category:** Education (alternative: Games › Word)
**Tags:** vocabulary, English learning, word game
**Contact email:** CONTACT_EMAIL
**Privacy policy URL:** the hosted `docs/privacy-policy.md` (GitHub Pages serves it from `docs/`)

### Graphics

| Asset | Size | Source |
| ----- | ---- | ------ |
| App icon | 512 × 512 PNG | `app/assets/brand/play_icon_512.png` |
| Feature graphic | 1024 × 500 PNG | `app/assets/brand/play_feature_graphic.png` |
| Phone screenshots | 1206 × 2412 (2:1, Play's tallest allowed) | `docs/store/screenshots/` — levels, a round, lap two, the result |
| Promo video (optional) | YouTube link | the presentation video, uploaded to YouTube |

## App content forms

**Privacy policy** — the hosted URL above.

**Ads** — No, the app does not contain ads.

**App access** — All functionality is available without special access (no
login).

**Content rating** (IARC questionnaire) — Category: Reference, News, or
Educational. Answer *No* to violence, sexuality, language, controlled
substances, gambling, user interaction/communication, sharing location, and
digital purchases. Expected rating: Everyone / PEGI 3.

**Target audience** — 13–15, 16–17, 18 and over. Leave the under-13 groups
unticked: including them puts the app under the Families policy, which
restricts analytics SDKs. "Could the app unintentionally appeal to
children?" — No.

**News app** — No. **Government app** — No. **Financial features** — None.
**Health** — None.

## Data safety

Answers reflect the prod build: Firebase Analytics and Crashlytics, speech
through the platform recogniser, scores stored on the device.

**Does your app collect or share any of the required user data types?** Yes.
**Is all of the user data collected by your app encrypted in transit?** Yes.
**Do you provide a way for users to request that their data is deleted?** Yes
(by email, per the privacy policy).

| Data type | Collected | Shared | Optional | Purpose |
| --------- | --------- | ------ | -------- | ------- |
| App activity › App interactions | Yes | No | No | Analytics |
| App info and performance › Crash logs | Yes | No | No | Analytics |
| App info and performance › Diagnostics | Yes | No | No | Analytics |
| Device or other IDs | Yes | No | No | Analytics |

Processing is ephemeral: no. Data is not used for advertising or tracking.

**Audio (voice or sound recordings): not collected.** The app never receives
audio. Recognition is performed by the device's system speech service
(Google on Android), a separate app with its own disclosures; Circular
Words receives transcribed text, uses it only to check the current answer,
and neither stores nor transmits it. Play's definition of "collected" is
data transmitted off the device *by your app or its SDKs*, which this is
not. The privacy policy still explains the platform service, and the
microphone permission's purpose, in full.

**Location, personal info, financial info, messages, photos, files,
contacts, calendar, health:** not collected.

## Release checklist

1. Play Console developer account verified.
2. App created with package name `com.yusubov.circularwords` (permanent).
3. Play App Signing enabled; upload the bundle signed with the upload key.
4. Build: `cd app && flutter build appbundle --release --flavor prod
   --dart-define-from-file=../config/prod.json`
   → `app/build/app/outputs/bundle/prodRelease/app-prod-release.aab`
5. Closed testing track: at least 12 testers opted in for 14 consecutive days
   (required for new personal developer accounts before production).
6. Store listing, graphics and every App content form above completed.
7. Promote to production.
