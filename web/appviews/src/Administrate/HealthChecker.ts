import { notNullish } from '@shared/ts-utils';
import type { HealthCheck, HealthCheckAction } from './administrate-store';
import type { Failable } from '../lib/failable';
import * as failable from '../lib/failable';

type ItemButton = {
  icon: string;
  label: string;
  action: HealthCheckAction;
};

export type ItemData = { title: string } & (
  | { state: 'checking' }
  | { state: 'ok'; message?: string }
  | { state: 'warn'; message: string; button?: ItemButton }
  | { state: 'fail'; message: string; button?: ItemButton }
  | { state: 'unexpected'; message?: string }
);

export default class HealthChecker {
  public constructor(
    private data: HealthCheck,
    private installedAppVersion: string,
    private screenshotMonitoringEnabled: boolean,
    private keystrokeMonitoringEnabled: boolean,
  ) {}

  public get items(): ItemData[] {
    return [
      this.appVersion,
      ...this.filterItems,
      this.screenRecordingPermission,
      this.keystrokeRecordingPermission,
      this.fullDiskAccessPermission,
      this.notificationsPermission,
      this.macOsUserType,
      this.accountStatus,
    ].filter(notNullish);
  }

  public get failingChecksCount(): number {
    return this.items.filter(({ state }) => state === `fail`).length;
  }

  public get isChecking(): boolean {
    return this.items.some(({ state }) => state === `checking`);
  }

  public get appVersion(): ItemData {
    const { latestAppVersion } = this.data;
    if (latestAppVersion === undefined) {
      return {
        title: `App Version`,
        state: `checking`,
      };
    } else if (failable.isError(latestAppVersion)) {
      return {
        title: `App Version`,
        state: `unexpected`,
        message: failable.errorMessage(latestAppVersion),
      };
    } else if (
      this.installedAppVersion === latestAppVersion.value ||
      this.installedAppVersion > latestAppVersion.value
    ) {
      return {
        title: `App Version`,
        state: `ok`,
        message: `You're up to date (${this.installedAppVersion})`,
      };
    } else {
      return {
        title: `App Version`,
        state: `warn`,
        message: `Update available (${latestAppVersion.value})`,
        button: {
          icon: `sync`,
          label: `Update`,
          action: `upgradeAppClicked`,
        },
      };
    }
  }

  public get screenRecordingPermission(): ItemData | undefined {
    if (!this.screenshotMonitoringEnabled) {
      return undefined;
    } else if (this.data.screenRecordingPermissionOk === undefined) {
      return {
        title: `Screen recording permission`,
        state: `checking`,
      };
    } else if (this.data.screenRecordingPermissionOk) {
      return {
        title: `Screen recording permission`,
        state: `ok`,
      };
    } else {
      return {
        title: `Screen recording permission`,
        state: `fail`,
        message: `Gertrude can't take screenshots until you give permission`,
        button: {
          icon: `cog`,
          label: `Fix permission`,
          action: `fixScreenRecordingPermissionClicked`,
        },
      };
    }
  }

  public get keystrokeRecordingPermission(): ItemData | undefined {
    if (!this.keystrokeMonitoringEnabled) {
      return undefined;
    } else if (this.data.keystrokeRecordingPermissionOk === undefined) {
      return {
        title: `Keystroke recording permission`,
        state: `checking`,
      };
    } else if (this.data.keystrokeRecordingPermissionOk) {
      return {
        title: `Keystroke recording permission`,
        state: `ok`,
      };
    } else {
      return {
        title: `Keystroke recording permission`,
        state: `fail`,
        message: `Gertrude can't monitor keystrokes until you give permission`,
        button: {
          icon: `cog`,
          label: `Fix permission`,
          action: `fixKeystrokeRecordingPermissionClicked`,
        },
      };
    }
  }

  public get fullDiskAccessPermission(): ItemData | undefined {
    if (this.data.fullDiskAccessPermissionOk === undefined) {
      return {
        title: `Full disk access permission`,
        state: `checking`,
      };
    } else if (this.data.fullDiskAccessPermissionOk) {
      return {
        title: `Full disk access permission`,
        state: `ok`,
      };
    } else {
      return {
        title: `Full disk access permission`,
        state: `fail`,
        message: `Gertrude needs permission to stop warnings when screenshots are taken`,
        button: {
          icon: `cog`,
          label: `Grant permission`,
          action: `fixFullDiskAccessPermissionClicked`,
        },
      };
    }
  }

  public get macOsUserType(): ItemData {
    if (this.data.macOsUserType === undefined) {
      return {
        title: `macOS user account type`,
        state: `checking`,
      };
    } else if (failable.isError(this.data.macOsUserType)) {
      return {
        title: `macOS user account type`,
        state: `unexpected`,
      };
    } else if (this.data.macOsUserType.value !== `standard`) {
      return {
        title: `Mac user has admin privileges`,
        state: `fail`,
        message: `Admin users can disable Gertrude if they have the password`,
        button: {
          icon: `user`,
          label: `Remove admin privilege`,
          action: `removeUserAdminPrivilegeClicked`,
        },
      };
    } else {
      return {
        title: `macOS user account type`,
        state: `ok`,
      };
    }
  }

  public get notificationsPermission(): ItemData {
    switch (this.data.notificationsSetting) {
      case `alert`:
        return {
          title: `Notification settings`,
          state: `ok`,
        };
      case `banner`:
        return {
          title: `Notification settings`,
          state: `warn`,
          message: `Set to "banner", recommended setting is "alert"`,
          button: {
            icon: `cog`,
            label: `Fix setting`,
            action: `fixNotificationPermissionClicked`,
          },
        };
      case `none`:
        return {
          title: `Notification settings`,
          state: `fail`,
          message: `Notifications disabled, child will miss critical updates`,
          button: {
            icon: `cog`,
            label: `Fix setting`,
            action: `fixNotificationPermissionClicked`,
          },
        };
      default:
        return {
          title: `Notification settings`,
          state: `checking`,
        };
    }
  }

  public get accountStatus(): ItemData {
    if (this.data.accountStatus === undefined) {
      return {
        title: `Gertrude account status`,
        state: `checking`,
      };
    }
    if (failable.isError(this.data.accountStatus)) {
      return {
        title: `Gertrude account status`,
        state: `unexpected`,
      };
    }
    switch (this.data.accountStatus.value) {
      case `active`:
        return {
          title: `Gertrude account status`,
          state: `ok`,
        };
      case `needsAttention`:
        return {
          title: `Gertrude account status`,
          state: `warn`,
          message: `Needs attention: log in to the Gertrude parents website for more details`,
        };
      default:
        return {
          title: `Gertrude account status`,
          state: `fail`,
          message: `Log in to the Gertrude parents website to resolve`,
        };
    }
  }

  public get filterItems(): ItemData[] {
    const { filterStatus, latestAppVersion } = this.data;
    if (
      filterStatus === undefined ||
      latestAppVersion === undefined ||
      filterStatus.case === `installing` ||
      (filterStatus.case === `communicationBroken` && filterStatus.repairing)
    ) {
      return [
        {
          title: `Filter status`,
          state: `checking`,
        },
      ];
    } else if (filterStatus.case === `disabled`) {
      return [
        {
          title: `Filter status`,
          state: `warn`,
          message: `Filter has been disabled`,
          button: {
            icon: `cog`,
            label: `Enable filter`,
            action: `enableFilterClicked`,
          },
        },
      ];
    } else if (filterStatus.case === `notInstalled`) {
      return [
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
      ];
    } else if (filterStatus.case === `installTimeout`) {
      return [
        {
          title: `Filter status`,
          state: `unexpected`,
          message: `Installation did not complete, try again`,
        },
      ];
    } else if (filterStatus.case === `unexpected`) {
      return [
        {
          title: `Filter status`,
          state: `unexpected`,
          message: `Unexpected error: try rebooting the computer`,
        },
      ];
    } else if (filterStatus.case === `communicationBroken`) {
      return [
        {
          title: `Filter to app communication broken`,
          state: `fail`,
          message: `If repair and recheck fails, <em>restart the computer</em> to resolve`,
          button: {
            icon: `sync`,
            label: `Attempt repair`,
            action: `repairFilterCommunicationClicked`,
          },
        },
      ];
    }

    const items: ItemData[] = [];
    const { version, numUserKeys } = filterStatus;

    if (this.shouldShowFilterOutOfDateItem(latestAppVersion, version)) {
      items.push({
        title: `Filter version`,
        state: `fail`,
        message: `Filter version out of date (${version})`,
        button: {
          icon: `sync`,
          label: `Reinstall filter`,
          action: `repairOutOfDateFilterClicked`,
        },
      });
    }

    if (numUserKeys > 0) {
      items.push({
        title: `Filter rules`,
        state: `ok`,
        message: `Looks good, ${numUserKeys} keys loaded`,
      });
    } else {
      items.push({
        title: `Filter rules`,
        state: `warn`,
        message: `No keys loaded, try refreshing rules`,
        button: {
          icon: `sync`,
          label: `Refresh rules`,
          action: `zeroKeysRefreshRulesClicked`,
        },
      });
    }

    return items;
  }

  shouldShowFilterOutOfDateItem(
    latestAppVersion: Failable<string>,
    currentFilterVersion: string,
  ): boolean {
    // if we don't know the latest app version...
    if (failable.isError(latestAppVersion)) {
      // ...only show if we're out of sync
      return currentFilterVersion !== this.installedAppVersion;
    }

    // but if app version is behind, no need to also nag about filter version
    if (this.installedAppVersion !== latestAppVersion.value) {
      return false;
    }

    // if app is current, and we're behind, show
    return currentFilterVersion !== this.installedAppVersion;
  }
}
