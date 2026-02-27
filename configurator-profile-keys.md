# Apple Configurator Profile Keys — Empirical Mapping

Systematic mapping of every Apple Configurator UI control to the exact plist key it writes.
Derived by toggling options one at a time and diffing the XML output.

Profile used: `~/configurator-profiles/GertieXferTest.mobileconfig`

## General

### Name

- **Key:** `PayloadDisplayName`
- **Type:** string
- Display name shown on device

### Identifier

- **Key:** `PayloadIdentifier`
- **Type:** string
- Unique ID; installing a profile with the same identifier replaces the existing one

### Organization

- **Key:** `PayloadOrganization`
- **Type:** string
- Optional

### Description

- **Key:** `PayloadDescription`
- **Type:** string
- Optional

### Consent Message

- **Key:** `ConsentText` > `default`
- **Type:** dict > string
- Shown during profile installation
- Stored as a dict to support localization (add language-specific keys)

### Security

Controls when the profile can be removed.

- **Key:** `PayloadRemovalDisallowed` (boolean)
- **Key:** `HasRemovalPasscode` (boolean, only when "With Authentication")
- Options:
  - **Always** — `PayloadRemovalDisallowed: false`
  - **With Authentication** — `PayloadRemovalDisallowed: true`,
    `HasRemovalPasscode: true`, plus a `com.apple.profileRemovalPassword` payload added to
    `PayloadContent` containing `RemovalPassword` (stored in plaintext)
  - **Never** — `PayloadRemovalDisallowed: true`, `HasRemovalPasscode: false`

### Automatically Remove Profile

- Options:
  - **Never** — no key written
  - **On Date** — `RemovalDate` (date, e.g. `2027-05-25T16:20:41Z`)
  - **After Interval** — `DurationUntilRemoval` (integer, seconds). UI fields are days +
    hours, stored as total seconds (e.g. 91d 3h = `7873200`)

---

**Also observed:** `PayloadUUID` regenerates on each save.

## Restrictions — Functionality Tab

Payload type: `com.apple.applicationaccess`

Note: unchecking a single checkbox caused Configurator to dump ALL restriction keys with
their default values. The full key set is captured below.

### Allow use of camera

- **Key:** `allowCamera`
- **Default:** `true`

#### Allow FaceTime (supervised only)

- **Key:** `allowVideoConferencing`
- **Default:** `true` (but was set to `false` when unchecked in our test)
- Child of: Allow use of camera

### Allow screenshots and screen recording

- **Key:** `allowScreenShot`
- **Default:** `true`

#### Allow AirPlay, View Screen by Classroom, and Screen Sharing

- **Key:** `allowRemoteScreenObservation`
- **Default:** `true`
- Child of: Allow screenshots and screen recording

##### Allow Classroom to perform AirPlay and View Screen without prompting (supervised only)

- **Key:** `forceClassroomUnpromptedScreenObservation`
- **Default:** `false` (unchecked by default — checking this sets `true`)
- Child of: Allow AirPlay, View Screen by Classroom, and Screen Sharing

### Allow AirDrop (supervised only)

- **Key:** `allowAirDrop`
- **Default:** `true`
- Note: only appears in dump when changed from default. Separate from
  `forceAirDropUnmanaged` which is the "Treat AirDrop as unmanaged destination" checkbox.

### Allow iMessage (supervised only)

- **Key:** `allowChat`
- **Default:** `true`

### Allow Apple Music (supervised only)

- **Key:** `allowMusicService`
- **Default:** `true`

### Allow Radio (supervised only)

- **Key:** `allowRadioService`
- **Default:** `true`

### Allow voice dialing while device is locked (deprecated in iOS 17)

- **Key:** `allowVoiceDialing`
- **Default:** `true`

### Allow Siri

- **Key:** `allowAssistant`
- **Default:** `true`

#### Allow Siri while device is locked

- **Key:** `allowAssistantWhileLocked`
- **Default:** `true`
- Child of: Allow Siri

#### Enable Siri profanity filter (supervised only)

- **Key:** `forceAssistantProfanityFilter`
- **Default:** `false` (unchecked by default — checking sets `true`)
- Child of: Allow Siri

#### Show user-generated content in Siri (supervised only)

- **Key:** `allowSpotlightInternetResults`
- **Default:** `true`
- Child of: Allow Siri

### Allow Siri Suggestions

- **Key:** `allowSpotlightInternetResults` (confirmed empirically)
- **Default:** `true`
- Note: same key as "Show user-generated content in Siri" child under Allow Siri.
  Configurator uses the same key for both UI labels.

### Allow Apple Books (supervised only)

- **Key:** `allowBookstore`
- **Default:** `true`

### Allow installing apps (supervised only)

- **Key:** `allowAppInstallation`
- **Default:** `true`

#### Allow installing apps using App Store (supervised only)

- **Key:** `allowUIAppInstallation`
- **Default:** `true`
- Child of: Allow installing apps

#### Allow automatic app downloads (supervised only)

- **Key:** `allowAutomaticAppDownloads`
- **Default:** `true`
- Child of: Allow installing apps

### Allow removing apps (supervised only)

- **Key:** `allowAppRemoval`
- **Default:** `true`

### Allow removing system apps (supervised only)

- **Key:** `allowSystemAppRemoval`
- **Default:** `true`

### Allow app clips (supervised only)

- **Key:** `allowAppClips`
- **Default:** `true`

### Allow in-app purchase

- **Key:** `allowInAppPurchases`
- **Default:** `true`

#### Require iTunes Store password for all purchases (deprecated in iOS 17)

- **Key:** `forceITunesStorePasswordEntry`
- **Default:** `false` (unchecked by default — checking sets `true`)
- Child of: Allow in-app purchase

### Allow iCloud backup

- **Key:** `allowCloudBackup`
- **Default:** `true`

### Allow iCloud documents & data (supervised only)

- **Key:** `allowCloudDocumentSync`
- **Default:** `true`

### Allow iCloud Keychain

- **Key:** `allowCloudKeychainSync` (confirmed empirically)
- **Default:** `true`
- Only appears in dump when changed from default

### Allow managed apps to store data in iCloud

- **Key:** `allowManagedAppsCloudSync`
- **Default:** `true`

### Allow backup of enterprise books

- **Key:** `allowEnterpriseBookBackup`
- **Default:** `true`

### Allow notes and highlights sync for enterprise books

- **Key:** `allowEnterpriseBookMetadataSync`
- **Default:** `true`

### Allow Shared Albums

- **Key:** `allowSharedStream`
- **Default:** `true`

### Allow iCloud Photos

- **Key:** `allowCloudPhotoLibrary`
- **Default:** `true`

### Allow My Photo Stream (disallowing can cause data loss; deprecated in iOS 17)

- **Key:** `allowPhotoStream`
- **Default:** `true`

### Allow automatic sync while roaming

- **Key:** `allowGlobalBackgroundFetchWhenRoaming`
- **Default:** `true`

### Allow USB drive access in Files app (supervised only)

- **Key:** `allowFilesUSBDriveAccess`
- **Default:** `true`

### Allow network drive access in Files app (supervised only)

- **Key:** `allowFilesNetworkDriveAccess`
- **Default:** `true`

### Force encrypted backups

- **Key:** `forceEncryptedBackup`
- **Default:** `false` (unchecked by default — checking sets `true`)

### Allow apps to request to track

- **Key:** `forceLimitAdTracking` (confirmed empirically)
- **Default:** `false` (UI checked = allow tracking)
- **INVERTED LOGIC:** Key name is about *forcing* tracking limits, UI label is about
  *allowing* tracking requests. UI checked (allow) = `false`. UI unchecked (block) = `true`.

### Allow personalized ads delivered by Apple

- **Key:** `allowApplePersonalizedAdvertising`
- **Default:** `true`

### Allow Erase All Content and Settings (supervised only)

- **Key:** `allowEraseContentAndSettings`
- **Default:** `true`

### Allow users to accept untrusted TLS certificates

- **Key:** `allowUntrustedTLSPrompt`
- **Default:** `true`

### Allow trusting new enterprise app authors

- **Key:** `allowEnterpriseAppTrust`
- **Default:** `true`

### Allow installing configuration profiles (supervised only)

- **Key:** `allowUIConfigurationProfileInstallation`
- **Default:** `true`

### Allow adding VPN configurations (supervised only)

- **Key:** `allowVPNCreation`
- **Default:** `true`

### Force automatic date and time (supervised only)

- **Key:** `forceAutomaticDateAndTime`
- **Default:** `false` (unchecked by default — checking sets `true`)

### Allow Classroom to lock to an app and lock the device without prompting (supervised only)

- **Key:** `forceClassroomUnpromptedAppAndDeviceLock`
- **Default:** `false` (unchecked by default — checking sets `true`)

### Automatically join Classroom classes without prompting (supervised only)

- **Key:** `forceClassroomAutomaticallyJoinClasses`
- **Default:** `false` (unchecked by default — checking sets `true`)

### Require teacher permission to leave Classroom unmanaged classes (supervised only)

- **Key:** `forceClassroomRequestPermissionToLeaveClasses`
- **Default:** `false` (unchecked by default — checking sets `true`)

### Force Wi-Fi power on (supervised only)

- **Key:** `forceWiFiPowerOn`
- **Default:** `false` (unchecked by default — checking sets `true`)

### Allow modifying account settings (supervised only)

- **Key:** `allowAccountModification` (confirmed empirically)
- **Default:** `true`
- Only appears in dump when changed from default

### Allow modifying Bluetooth settings (supervised only)

- **Key:** `allowBluetoothModification`
- **Default:** `true`

### Allow modifying cellular data app settings (supervised only)

- **Key:** `allowAppCellularDataModification`
- **Default:** `true`

### Allow modifying cellular plan settings (supervised only)

- **Key:** `allowCellularPlanModification`
- **Default:** `true`

### Allow modifying eSIM settings (supervised only)

- **Key:** `allowESIMModification`
- **Default:** `true`

### Allow modifying device name (supervised only)

- **Key:** `allowDeviceNameModification`
- **Default:** `true`

### Allow modifying notification settings (supervised only)

- **Key:** `allowNotificationsModification`
- **Default:** `true`

### Allow modifying passcode (supervised only)

- **Key:** `allowPasscodeModification`
- **Default:** `true`

### Allow modifying Touch ID fingerprints / Face ID faces (supervised only)

- **Key:** `allowFingerprintModification`
- **Default:** `true`

### Allow Screen Time (supervised only)

- **Key:** `allowEnablingRestrictions` (confirmed empirically)
- **Default:** `true`
- **IMPORTANT for Jonas issue:** This is the Screen Time toggle. If our profile doesn't
  explicitly set this to `true`, a supervised device may default to disabling Screen Time.

### Allow modifying Wallpaper (supervised only)

- **Key:** `allowWallpaperModification`
- **Default:** `true`

### Allow modifying Personal Hotspot settings (supervised only)

- **Key:** `allowPersonalHotspotModification`
- **Default:** `true`

### Allow Find My Friends (supervised only)

- **Key:** `allowFindMyFriends`
- **Default:** `true`

### Allow Find My Devices (supervised only)

- **Key:** `allowFindMyDevice`
- **Default:** `true`

### Allow modifying Find My Friends settings (supervised only)

- **Key:** `allowFindMyFriendsModification` (confirmed empirically)
- **Default:** `true`
- Separate from `allowFindMyFriends` — this controls modifying the settings, not access
- Only appears in dump when changed from default

### Allow USB accessories while device is locked (supervised only)

- **Key:** `allowUSBRestrictedMode`
- **Default:** `true` (UI unchecked = key `true`)
- **INVERTED LOGIC:** Key name is about *restricting* USB, UI label is about *allowing*.
  `allowUSBRestrictedMode: true` = USB accessories **blocked** while locked (UI unchecked).
  `allowUSBRestrictedMode: false` = USB accessories **allowed** while locked (UI checked).
  Be careful with this one — setting the key to `true` does the opposite of what the name
  suggests if you're thinking in terms of the UI.

### Allow pairing with non-Configurator hosts (supervised only)

- **Key:** `allowHostPairing` (confirmed empirically)
- **Default:** `true`
- Only appears in dump when changed from default

### Allow putting into recovery mode from an unpaired device (supervised only)

- **Key:** `allowUnpairedExternalBootToRecovery`
- **Default:** `false` (unchecked by default)

### Allow documents from managed sources in unmanaged destinations

- **Key:** `allowOpenFromManagedToUnmanaged`
- **Default:** `true`

### Allow documents from unmanaged sources in managed destinations

- **Key:** `allowOpenFromUnmanagedToManaged`
- **Default:** `true`

### Treat AirDrop as unmanaged destination

- **Key:** `forceAirDropUnmanaged`
- **Default:** `false` (unchecked by default — checking sets `true`)

### Allow Handoff

- **Key:** `allowActivityContinuation`
- **Default:** `true`

### Allow sending diagnostic and usage data to Apple

- **Key:** `allowDiagnosticSubmission` (confirmed empirically)
- **Default:** `true`
- Only appears in dump when changed from default
- Unchecking grays out child: "Allow modifying diagnostics settings"

#### Allow modifying diagnostics settings (supervised only)

- **Key:** `allowDiagnosticSubmissionModification` (confirmed empirically)
- **Default:** `true`
- Child of: Allow sending diagnostic and usage data to Apple
- Only appears in dump when changed from default

### Allow Touch ID / Face ID to unlock device

- **Key:** `allowFingerprintForUnlock`
- **Default:** `true`

### Allow password AutoFill (supervised only)

- **Key:** `allowPasswordAutoFill`
- **Default:** `true`

### Require Touch ID / Face ID authentication before AutoFill (supervised only)

- **Key:** `forceAuthenticationBeforeAutoFill`
- **Default:** `false` (unchecked by default — checking sets `true`)

### Allow unlock with Apple Watch

- **Key:** `allowAutoUnlock`
- **Default:** `true`

### Force Apple Watch wrist detection

- **Key:** `forceWatchWristDetection`
- **Default:** `false` (unchecked by default — checking sets `true`)

### Allow pairing with Apple Watch (supervised only)

- **Key:** `allowPairedWatch`
- **Default:** `true`

### Require passcode on first AirPlay pairing

- **Key:** `forceAirPlayIncomingRequestsPairingPassword` (confirmed empirically)
- **Key:** `forceAirPlayOutgoingRequestsPairingPassword` (confirmed empirically)
- **Default:** both `false` (unchecked by default — checking sets both to `true`)
- One UI checkbox writes two keys (incoming + outgoing)

### Join only Wi-Fi networks installed by a Wi-Fi payload (supervised only)

- **Key:** `forceWiFiWhitelisting`
- **Default:** `false` (unchecked by default — checking sets `true`)

### Allow setting up new nearby devices (supervised only)

- **Key:** `allowProximitySetupToNewDevice`
- **Default:** `true`

### Allow proximity based password sharing requests (supervised only)

- **Key:** `allowPasswordProximityRequests`
- **Default:** `true`

### Allow password sharing (supervised only)

- **Key:** `allowPasswordSharing`
- **Default:** `true`

### Allow AirPrint (supervised only)

- **Key:** `allowAirPrint`
- **Default:** `true`

#### Allow discovery of AirPrint printers using iBeacons (supervised only)

- **Key:** `allowAirPrintiBeaconDiscovery`
- **Default:** `true`
- Child of: Allow AirPrint

#### Allow storage of AirPrint credentials in Keychain (supervised only)

- **Key:** `allowAirPrintCredentialsStorage`
- **Default:** `true`
- Child of: Allow AirPrint

#### Disallow AirPrint to destinations with untrusted certificates (supervised only)

- **Key:** `forceAirPrintTrustedTLSRequirement`
- **Default:** `false` (unchecked by default — checking sets `true`)
- Child of: Allow AirPrint

### Allow predictive keyboard (supervised only)

- **Key:** `allowPredictiveKeyboard`
- **Default:** `true`

### Allow keyboard shortcuts (supervised only)

- **Key:** `allowKeyboardShortcuts`
- **Default:** `true`

### Allow continuous path keyboard (supervised only)

- **Key:** `allowContinuousPathKeyboard`
- **Default:** `true`

### Allow auto correction (supervised only)

- **Key:** `allowAutoCorrection`
- **Default:** `true`

### Allow spell check (supervised only)

- **Key:** `allowSpellCheck`
- **Default:** `true`

### Allow Define (supervised only)

- **Key:** `allowDefinitionLookup`
- **Default:** `true`

### Allow dictation (supervised only)

- **Key:** `allowDictation`
- **Default:** `true`

### Allow Wallet notifications in Lock screen

- **Key:** `allowPassbookWhileLocked`
- **Default:** `true`

### Show Control Center in Lock screen

- **Key:** `allowLockScreenControlCenter` (confirmed empirically)
- **Default:** `true`
- Only appears in dump when changed from default

### Show Notification Center in Lock screen

- **Key:** `allowLockScreenNotificationsView` (confirmed empirically)
- **Default:** `true`
- Only appears in dump when changed from default

### Show Today view in Lock screen

- **Key:** `allowLockScreenTodayView` (confirmed empirically)
- **Default:** `true`
- Only appears in dump when changed from default

### Allow pairing with Remote app (tvOS only)

- **Key:** `allowRemoteAppPairing`
- **Default:** `true`

### Allow incoming AirPlay requests (tvOS only)

- **Key:** `allowAirPlayIncomingRequests`
- **Default:** `true`

### Allow device sleep (tvOS only)

- **Key:** `allowDeviceSleep`
- **Default:** `true`

### Defer software updates for ___ days (supervised only)

- **Key:** `forceDelayedSoftwareUpdates`
- **Default:** `false` (unchecked by default — checking sets `true`)
- Likely also writes a `enforcedSoftwareUpdateDelay` integer key for the day count

## Restrictions — Apps Tab

Payload type: `com.apple.applicationaccess` (same payload as Functionality tab)

### Allow use of iTunes Store (supervised only)

- **Key:** `allowiTunes`
- **Default:** `true`

### Allow use of News (supervised only)

- **Key:** `allowNews`
- **Default:** `true`

### Allow use of Podcasts (supervised only)

- **Key:** `allowPodcasts` (confirmed empirically)
- **Default:** `true`
- Only appears in dump when changed from default

### Allow use of Game Center (supervised only)

- **Key:** `allowGameCenter`
- **Default:** `true`

#### Allow multiplayer gaming (supervised only)

- **Key:** `allowMultiplayerGaming`
- **Default:** `true`
- Child of: Allow use of Game Center

#### Allow adding Game Center friends (supervised only)

- **Key:** `allowAddingGameCenterFriends`
- **Default:** `true`
- Child of: Allow use of Game Center

### Allow use of Safari (supervised only)

- **Key:** `allowSafari`
- **Default:** `true`

#### Enable AutoFill (supervised only)

- **Key:** `safariAllowAutoFill`
- **Default:** `true`
- Child of: Allow use of Safari

#### Force fraud warning

- **Key:** `safariForceFraudWarning`
- **Default:** `false` (unchecked by default — checking sets `true`)
- Child of: Allow use of Safari

#### Enable JavaScript

- **Key:** `safariAllowJavaScript`
- **Default:** `true`
- Child of: Allow use of Safari

#### Block pop-ups

- **Key:** `safariAllowPopups`
- **Default:** `true`
- **INVERTED LOGIC (likely):** "Block pop-ups" unchecked = `allowPopups: true`.
  Checking "Block pop-ups" likely sets `safariAllowPopups: false`. Needs confirmation.
- Child of: Allow use of Safari

#### Accept cookies

- **Key:** `safariAcceptCookies`
- **Type:** real (float)
- **Default:** `2` ("Always")
- Other values TBD
- Child of: Allow use of Safari

### Restrict App Usage (supervised only)

Dropdown with three options:

- **Allow all apps** — no additional key written (default)
- **Do not allow some apps** — `blacklistedAppBundleIDs` (array of bundle ID strings,
  confirmed empirically)
- **Only allow some apps** — `whitelistedAppBundleIDs` (array of bundle ID strings,
  confirmed empirically)
- The blacklist/whitelist keys are mutually exclusive — only one is present at a time

## Restrictions — Media Content Tab

Payload type: `com.apple.applicationaccess` (same payload as Functionality and Apps tabs)

### Ratings region

- **Key:** `ratingRegion`
- **Type:** string
- **Default:** `us` ("United States")

### Allowed content ratings

#### Movies

- **Key:** `ratingMovies`
- **Type:** integer
- **Default:** `1000` ("Allow All Movies")
- Lower values = more restrictive. Exact value-to-rating mapping TBD.

#### TV Shows

- **Key:** `ratingTVShows`
- **Type:** integer
- **Default:** `1000` ("Allow All TV Shows")
- Lower values = more restrictive. Exact value-to-rating mapping TBD.

#### Apps

- **Key:** `ratingApps`
- **Type:** integer
- **Default:** `1000` ("Allow All Apps")
- Lower values = more restrictive. Exact value-to-rating mapping TBD.

### Allow playback of explicit music, podcasts & iTunes U media (supervised only)

- **Key:** `allowExplicitContent`
- **Default:** `true`

### Allow explicit sexual content in Apple Books

- **Key:** `allowBookstoreErotica`
- **Default:** `true`
