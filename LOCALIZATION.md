# MINOVA Localization

## Supported languages

The app bundles these languages locally so language switching works without a
network connection:

| Display name | Locale |
| --- | --- |
| English | `en` |
| हिंदी | `hi` |
| ଓଡ଼ିଆ | `or` |
| తెలుగు | `te` |
| বাংলা | `bn` |
| मराठी | `mr` |
| छत्तीसगढ़ी | `hne` |
| ᱥᱟᱱᱛᱟᱲᱤ | `sat` |

Chhattisgarhi uses the `hne` locale identifier and Santali uses `sat`. These
codes are internal and are never shown in the UI.

## Architecture

- Translation source files live in `l10n/app_<locale>.arb`.
- Flutter generates typed bindings into
  `lib/core/localization/generated/` using `l10n.yaml`.
- `AppLanguage` is the central language model.
- `LanguageController` persists the selected code with `SharedPreferences`.
- `MaterialApp` watches the controller, so switching is immediate and works
  offline.
- First launch shows the large-touch language picker. Login and Profile can
  open it again at any time.

The English ARB file is the template. Missing generated translations fall back
to the template locale. New user-facing strings must be added to every ARB
file before the feature is considered complete.

## Translation rules

Use short, direct language that tells a mine worker what to do or what happened.
Prefer “Internet is off” over “network connectivity unavailable”. Keep critical
safety actions clear and pair them with an icon. Do not expose locale codes,
database enum names, UUIDs, or backend terminology in the main UI.

Internal values such as `pendingSync`, roles, severity, and inspection types stay
language-independent. Only their presentation is translated.

## User-entered and legal content

Inspector-entered notes, voice transcriptions, observations, and document files
are stored exactly as entered or uploaded. They are never overwritten with a
translation. Future normalized or translated fields must be separate fields.
Voice and future AI metadata should use an `inputLanguage` or
`originalLanguage` value. Uploaded legal documents remain in their original
form; only app metadata and controls are localized.

When the Firebase profile is connected, store only the selected language code in
`preferredLanguage`; never store translated UI strings.

## Adding a language

1. Add an `AppLanguage` entry with its internal code and native name.
2. Add `l10n/app_<code>.arb` with the same keys as `app_en.arb`.
3. Run `flutter gen-l10n`.
4. Add the locale to the localization test and check long labels at large text
   sizes on Login, Home, Report, Inspection, Records, and Profile.

  ## Current status

  The eight bundled locales and offline language switching are implemented.
  Remaining work is a physical large-text overflow pass across every long-form
  field workflow; no locale codes or translated database values are used in the
  application data model.
5. Run `flutter analyze` and `TEMP=D:\temp flutter test`.

## QA procedure

Check all eight language choices offline. Verify that the app restarts with the
same language, logout does not clear it, buttons wrap instead of clipping, and
critical actions remain icon-plus-label controls. Test both first-launch login
and Profile -> Language switching. Use widget tests for key presence and a
manual device pass for overflow at increased text scale.
