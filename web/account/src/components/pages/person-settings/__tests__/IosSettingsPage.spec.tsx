import { EXTENDED_RESTRICTION_GROUPS } from '@shared/pairql/supervision';
import { renderToStaticMarkup } from 'react-dom/server';
import { describe, expect, test } from 'vitest';
import { iosDeviceSettingsExtendedControls } from '../../../storybook/fixtures';
import IosSettingsPage from '../IosSettingsPage';

describe(`legacy supervision copy`, () => {
  test.each([
    { deviceType: `iPhone`, modelIdentifier: `iPhone15,4` },
    { deviceType: `iPad`, modelIdentifier: `iPad13,16` },
  ])(
    `preserves the headings, descriptions, warnings, and inputs for $deviceType`,
    ({ deviceType, modelIdentifier }) => {
      const markup = renderToStaticMarkup(
        <IosSettingsPage
          state={{
            status: `success`,
            data: {
              ...iosDeviceSettingsExtendedControls,
              modelIdentifier,
              podcasts: { subscription: { case: `complimentary` } },
              blocker: {
                ...iosDeviceSettingsExtendedControls.blocker!,
                profileSettings: {
                  preventProtectionRemoval: false,
                  allowDeletingApps: true,
                  allowFactoryReset: true,
                  allowInstallingApps: false,
                },
                extendedSupervisionControls: {
                  whitelistedAppBundleIds: [],
                  webAllowList: [],
                  forceDelayedSoftwareUpdates: true,
                  enforcedSoftwareUpdateDelay: 45,
                },
              },
            },
          }}
          defaultExpandedSection="blocker"
          onSaveBlockedGroups={() => undefined}
          onSaveProfile={() => undefined}
          onRequestPodcastsPinReset={() => Promise.resolve(null)}
        />,
      );
      const text = markup
        .replace(/<[^>]*>/g, ``)
        .replace(/&amp;/g, `&`)
        .replace(/&#x27;/g, `'`)
        .replace(/&quot;/g, `"`);
      const expectedCopy = [
        `Supervision Profile Settings`,
        `After changing any setting below, you’ll need to sync the profile on the ${deviceType} by opening the Gertrude app and going to Info → Sync Profile.`,
        `Prevent protection removal`,
        `Make it impossible for the ${deviceType} user to remove Gertrude’s protection.`,
        `The ${deviceType} user may remove the profile in order to stop Gertrude’s protection and uninstall.`,
        `Allow deleting apps`,
        `Keeping this off prevents the ${deviceType} user from deleting the Gertrude app, but also prevents them from deleting any app. Enable temporarily if you need to delete some apps from the ${deviceType}, then re-enable.`,
        `The user can delete apps (including Gertrude) from their ${deviceType}`,
        `Allow factory reset`,
        `Allow the ${deviceType} to be erased and reset to factory settings, bypassing protection.`,
        `The user will be able to erase the ${deviceType} removing Gertrude and all restrictions`,
        `Allow installing apps`,
        `Allow the ${deviceType} user to install new apps from the App Store. Turn this off to remove the App Store icon entirely and block app installation.`,
        `Extended controls`,
        `Fine-grained restrictions for this supervised ${deviceType}. Anything you turn on (purple) is enforced on the device; anything left off stays available.`,
        `Only allow approved apps`,
        `Hide every app on the ${deviceType} except the ones you specifically approve.`,
        `With no apps approved, nearly every app will be hidden from the ${deviceType}.`,
        `Only allow approved websites`,
        `Block every website on the ${deviceType} except the ones you specifically approve.`,
        `With no websites approved, the entire web will be blocked on the ${deviceType}.`,
        `Add app`,
        `Add website`,
        `Delay for`,
        `days after release`,
      ];
      for (const copy of expectedCopy) expect(text).toContain(copy);
      for (const group of EXTENDED_RESTRICTION_GROUPS) {
        expect(text).toContain(group.title);
        expect(text).toContain(group.description);
        for (const control of group.controls) {
          expect(text).toContain(control.label);
          if (control.hint) expect(text).toContain(control.hint);
        }
      }
      expect(text.match(/After changing any setting below/g)).toHaveLength(1);
      expect(text.match(/Save settings/g)).toHaveLength(1);
      expect(text.slice(text.indexOf(`Extended controls`))).not.toContain(`0 of`);
      expect(markup).toContain(
        `placeholder="App bundle ID (e.g. com.apple.mobilesafari)"`,
      );
      expect(markup).toContain(`placeholder="Name (e.g. Weather)"`);
      expect(markup).toContain(`placeholder="URL (e.g. https://weather.com)"`);
      expect(markup).toContain(`min="1" max="90"`);
      expect(markup.indexOf(`With no apps approved`)).toBeLessThan(
        markup.indexOf(`placeholder="App bundle ID`),
      );
      expect(markup.indexOf(`With no websites approved`)).toBeLessThan(
        markup.indexOf(`placeholder="Name`),
      );
    },
  );

  test.each([
    { isSupervised: true, profileVisible: true },
    { isSupervised: false, profileVisible: false },
  ])(
    `does not show gated controls without access on a device with isSupervised=$isSupervised`,
    ({ isSupervised, profileVisible }) => {
      const markup = renderToStaticMarkup(
        <IosSettingsPage
          state={{
            status: `success`,
            data: {
              ...iosDeviceSettingsExtendedControls,
              podcasts: { subscription: { case: `complimentary` } },
              blocker: {
                ...iosDeviceSettingsExtendedControls.blocker!,
                isSupervised,
                extendedSupervisionControls: undefined,
              },
            },
          }}
          onSaveBlockedGroups={() => undefined}
          onSaveProfile={() => undefined}
          onRequestPodcastsPinReset={() => Promise.resolve(null)}
        />,
      );
      expect(markup.includes(`Supervision Profile Settings`)).toBe(profileVisible);
      expect(markup.includes(`Save settings`)).toBe(profileVisible);
      expect(markup).not.toContain(`Extended controls`);
      expect(markup).not.toContain(`Only allow approved apps`);
      expect(markup).not.toContain(`Fine-grained restrictions`);
    },
  );
});
