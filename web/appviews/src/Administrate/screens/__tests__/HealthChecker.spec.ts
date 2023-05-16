import { expect, it, test, describe } from 'vitest';
import type { HealthCheck } from '../../administrate-store';
import HealthChecker from '../../HealthChecker';

describe(`HealthChecker`, () => {
  describe(`filterItems`, () => {
    test(`returns single "checking" state when filterStatus is undefined`, () => {
      const checker = makeChecker({ filterStatus: undefined });
      expect(checker.filterItems).toEqual([
        { title: `Filter status`, state: `checking` },
      ]);
    });

    it(`returns single "warn" when filter not installed`, () => {
      const checker = makeChecker({ filterStatus: { case: `notInstalled` } });
      expect(checker.filterItems).toEqual([
        {
          title: `Filter status`,
          state: `warn`,
          message: `Filter has not been installed`,
          button: {
            icon: `cog`,
            label: `Install filter`,
            action: `installFilterClicked`,
          },
        },
      ]);
    });

    it(`returns single "unexpected" when unexpected error`, () => {
      const checker = makeChecker({ filterStatus: { case: `unexpected` } });
      expect(checker.filterItems).toEqual([
        {
          title: `Filter status`,
          state: `unexpected`,
          message: `Unexpected error: try rebooting the computer`,
        },
      ]);
    });

    it(`returns  single "fail" when communication problem`, () => {
      const checker = makeChecker({
        filterStatus: { case: `communicationBroken` },
      });
      expect(checker.filterItems).toEqual([
        {
          title: `Filter to app communication`,
          state: `fail`,
          message: `Verification failed`,
          button: {
            icon: `sync`,
            label: `Restart filter`,
            action: `repairFilterCommunicationClicked`,
          },
        },
      ]);
    });

    test(`filter version behind up-to-date app version`, () => {
      const checker = makeChecker({
        filterStatus: {
          case: `installed`,
          version: `0.9.0`, // <-- behind latest app version
          numUserKeys: 3,
        },
      });
      expect(checker.filterItems).toEqual([
        {
          title: `Filter version`,
          state: `fail`,
          message: `Filter version out of date (0.9.0)`,
          button: {
            icon: `sync`,
            label: `Reinstall filter`,
            action: `repairOutOfDateFilterClicked`,
          },
        },
        {
          title: `Filter rules`,
          state: `ok`,
          message: `Looks good, 3 keys loaded`,
        },
      ]);
    });

    test(`filter version differs from app version, api latest unknown`, () => {
      const checker = makeChecker({
        latestAppVersion: { case: `error` }, // <-- we don't know latest app version
        filterStatus: { case: `installed`, version: `0.9.0`, numUserKeys: 3 },
      });
      expect(checker.filterItems).toEqual([
        {
          title: `Filter version`,
          state: `fail`, // <-- since versions are different, we can still fail
          message: `Filter version out of date (0.9.0)`,
          button: {
            icon: `sync`,
            label: `Reinstall filter`,
            action: `repairOutOfDateFilterClicked`,
          },
        },
        {
          title: `Filter rules`,
          state: `ok`,
          message: `Looks good, 3 keys loaded`,
        },
      ]);
      expect(checker.appVersion).toEqual({
        title: `App Version`,
        state: `unexpected`,
      });
    });

    test(`filter version = app version, api latest unknown`, () => {
      const checker = makeChecker({
        latestAppVersion: { case: `error` }, // <-- we don't know latest app version
        filterStatus: {
          case: `installed`,
          version: `1.0.0`, // <-- but filter same as app version, so OK
          numUserKeys: 3,
        },
      });
      // don't show filter version item, or communication item
      expect(checker.filterItems).toEqual([
        {
          title: `Filter rules`,
          state: `ok`,
          message: `Looks good, 3 keys loaded`,
        },
      ]);
      expect(checker.appVersion).toEqual({
        title: `App Version`,
        state: `unexpected`,
      });
    });

    test(`filter version = app version, but both behind api latest`, () => {
      const checker = makeChecker({
        latestAppVersion: { case: `ok`, value: `1.0.1` }, // <-- new version!
        filterStatus: {
          case: `installed`,
          version: `1.0.0`,
          numUserKeys: 3,
        },
      });
      // show num keys ok item, but not filter version, since...
      expect(checker.filterItems).toEqual([
        {
          title: `Filter rules`,
          state: `ok`,
          message: `Looks good, 3 keys loaded`,
        },
      ]);
      expect(checker.appVersion).toEqual({
        title: `App Version`,
        state: `warn`,
        message: `Update available (1.0.1)`,
        button: {
          icon: `sync`,
          label: `Update`,
          action: `upgradeAppClicked`, // <-- ...app version has action button
        },
      });
    });
  });
});

function makeChecker(
  overrides?: Partial<HealthCheck>,
  installedAppVersion = `1.0.0`,
  screenshotMonitoringEnabled = true,
  keystrokeMonitoringEnabled = true,
): HealthChecker {
  const healthCheck: HealthCheck = {
    latestAppVersion: { case: `ok`, value: `1.0.0` },
    filterStatus: { case: `installed`, version: `1.0.0`, numUserKeys: 3 },
    accountStatus: { case: `ok`, value: `active` },
    screenRecordingPermissionOk: true,
    keystrokeRecordingPermissionOk: true,
    macOsUserType: { case: `ok`, value: `admin` },
    notificationsSetting: `banner`,
    ...overrides,
  };
  return new HealthChecker(
    healthCheck,
    installedAppVersion,
    screenshotMonitoringEnabled,
    keystrokeMonitoringEnabled,
  );
}
