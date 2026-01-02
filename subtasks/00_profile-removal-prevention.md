# Preventing Mobile Config Profile Removal

## Key Mechanisms

### `PayloadRemovalDisallowed` (top-level profile key)

| Device Type          | Effect                                                     |
| -------------------- | ---------------------------------------------------------- |
| **Supervised iOS**   | Profile **cannot be removed** - no "Remove Profile" button |
| **Unsupervised iOS** | Ignored - user can still remove profile                    |
| **macOS**            | Requires admin password to remove                          |

### `RemovalPassword` payload (not recommended)

Requires password before removal. **Use `PayloadRemovalDisallowed` instead** - password
approach adds complexity and shows a visible but unusable "Remove" button (worse UX).

## Critical Insight

On supervised devices, `PayloadRemovalDisallowed: true` completely prevents removal - no
"Remove Profile" button in Settings. This is exactly what Tech Lockdown does.

## Profile Replacement Mechanism

Installing a profile with the **same `PayloadIdentifier`** as an existing profile causes
iOS to **replace** the old one. This enables:

1. **Profile updates** - Change filter rules by having user re-download
2. **Profile removal** - Generate profile with `PayloadRemovalDisallowed: false`, user
   installs it (replacing locked profile), then can remove it

## Recommended Gertrude Flow

### Initial Setup

1. Supervision tool → Device becomes supervised
2. Profile download → Install with `PayloadRemovalDisallowed: true`
3. Result → Profile locked, no remove button

### Profile Updates

1. Parent makes changes in dashboard → "Sync required" for device
2. Child re-downloads profile (same Safari WebView flow)
3. New profile replaces old (same `PayloadIdentifier`), changes take effect

### Profile Removal

1. Parent triggers "unlock profile" in dashboard
2. API generates profile with same identifier but `PayloadRemovalDisallowed: false`
3. Child downloads/installs → old locked profile replaced with unlocked one
4. Child can now remove from Settings → VPN & Device Management

### Full Unsupervision (optional)

Parent runs supervision tool → "Remove Supervision" → Device reboots unsupervised

## Escape Hatches

Child can always **factory reset** (Erase All Content and Settings) - removes supervision
AND profile, but loses all data. To prevent, add to restrictions payload:

```xml
<key>allowEraseContentAndSettings</key>
<false/>
```

## Advantages

1. **Dashboard control** - Parent manages from web, no physical computer for ongoing mgmt
2. **Supervision tool for setup/teardown only**
3. **Same UX for updates and removal** - Safari download flow
4. **No passwords to manage**
5. **Device stays supervised** - Can update Gertrude while keeping other supervision
   benefits

## Technical Details

### Web Content Filter (`com.apple.webcontent-filter`)

- **Supervised devices only** for system-wide filtering
- Required: `FilterType: "Plugin"`, `PluginBundleID`, `FilterBrowsers`, `FilterSockets`

### PayloadIdentifier Behavior

- **Same PayloadIdentifier** = iOS replaces existing profile
- **Different PayloadIdentifier** = iOS installs as separate profile
- Use consistent identifier (e.g., `app.gertrude.contentfilter`) for all versions

### Key Profile Keys

```xml
<key>PayloadIdentifier</key>
<string>app.gertrude.contentfilter</string>
<key>PayloadRemovalDisallowed</key>
<true/>
```

## Sources

- [Apple - Configuration Enforcement](https://support.apple.com/guide/security/configuration-enforcement-secf6fb9f053/web)
- [Apple - Device Supervision](https://support.apple.com/guide/deployment/about-device-supervision-dep1d89f0bff/web)
- [Apple - Web Content Filter Payload](https://support.apple.com/guide/deployment/web-content-filter-payload-settings-depc77c9609/web)
- [Apple - Restrictions for Supervised Devices](https://support.apple.com/guide/deployment/restrictions-for-supervised-devices-dep6b5ae23e9/web)
- [Tech Lockdown - MDM vs Supervised](https://www.techlockdown.com/blog/ios-mobile-device-management-vs-supervised-device)
- [Configuration Profile Reference PDF](https://developer.apple.com/business/documentation/Configuration-Profile-Reference.pdf)
