# Localization

This app uses Swift's native localization system with typesafe enums and `.xcstrings`
files.

## Architecture

Localization is split by package, with each defining its own `LocalizedStringKey` enum and
`lstr()` function:

- **lib-views**: UI-related strings - episodes, shows, search, settings, now playing, PIN,
  welcome
- **lib-tca**: Business logic strings - onboarding, add show, podcasts management, review
  requests

## Implementation

### LocalizedStringKey Enums

Each package defines its own enum in `Lib/Localization.swift`:

```swift
enum LocalizedStringKey: String {
  case episodeArchiveEpisode = "episode.archiveEpisode"
  case episodeDeleteDownload = "episode.deleteDownload"
  // ...
}
```

- NOTE: before adding a new key, check both packages to see if it already exists.

### lstr(\_:) Function

Both packages provide an identical helper:

```swift
func lstr(_ key: LocalizedStringKey) -> String {
  String(localized: String.LocalizationValue(key.rawValue), bundle: .module)
}
```

This converts enum cases to localized strings using the `.module` bundle reference.

### .xcstrings Files

String catalogs are located at `Sources/Resources/Localizable.xcstrings` in each package:

- `lib-views/Sources/Resources/Localizable.xcstrings`
- `lib-tca/Sources/Resources/Localizable.xcstrings`

## Sample Usage

```swift
Text(lstr(.episodeArchiveEpisode))
```

The `lstr()` function provides type safety and returns the translated string for the
device's current language.
