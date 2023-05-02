import type { HealthCheck } from './administrate-store';
import * as failable from '../lib/failable';

export type HealthCheckStatus = 'checking' | 'warn' | 'fail' | 'ok' | 'errorDetermining';

export default class HealthChecker {
  public constructor(
    private data: HealthCheck,
    private installedAppVersion: string,
    private screenshotMonitoringEnabled: boolean,
    private keystrokeMonitoringEnabled: boolean,
  ) {}

  public get failingChecksCount(): number {
    return [
      this.appVersion,
      this.filterVersion,
      this.screenRecordingPermission,
      this.keystrokeRecordingPermission,
      this.macOsUserType,
      this.filterCommunicationVerified,
      this.notificationsPermission,
      this.accountStatus,
      this.numFilterKeys,
    ].filter((status) => status === `fail`).length;
  }

  public get isChecking(): boolean {
    return (
      [
        this.appVersion,
        this.filterVersion,
        this.screenRecordingPermission,
        this.keystrokeRecordingPermission,
        this.macOsUserType,
        this.filterCommunicationVerified,
        this.notificationsPermission,
        this.accountStatus,
        this.numFilterKeys,
      ].filter((status) => status === `checking`).length > 0
    );
  }

  public get appVersion(): HealthCheckStatus {
    const { latestAppVersion } = this.data;
    if (latestAppVersion === undefined) {
      return `checking`;
    }
    if (failable.isError(latestAppVersion)) {
      return `errorDetermining`;
    }
    return this.installedAppVersion === latestAppVersion.value ? `ok` : `warn`;
  }

  public get filterVersion(): HealthCheckStatus {
    const { filterData, latestAppVersion } = this.data;
    if (filterData === undefined || latestAppVersion === undefined) {
      return `checking`;
    }
    if (failable.isError(filterData) || failable.isError(latestAppVersion)) {
      return `errorDetermining`;
    }
    return filterData.value.version === latestAppVersion.value ? `ok` : `fail`;
  }

  public get screenRecordingPermission(): HealthCheckStatus {
    switch (this.data.screenRecordingPermissionOk) {
      case undefined:
        return `checking`;
      case true:
        return `ok`;
      default:
        return this.screenshotMonitoringEnabled ? `fail` : `ok`;
    }
  }

  public get keystrokeRecordingPermission(): HealthCheckStatus {
    switch (this.data.keystrokeRecordingPermissionOk) {
      case undefined:
        return `checking`;
      case true:
        return `ok`;
      default:
        return this.keystrokeMonitoringEnabled ? `fail` : `ok`;
    }
  }

  public get macOsUserType(): HealthCheckStatus {
    if (this.data.macOsUserType === undefined) {
      return `checking`;
    }
    if (failable.isError(this.data.macOsUserType)) {
      return `errorDetermining`;
    }
    return this.data.macOsUserType.value === `standard` ? `ok` : `fail`;
  }

  public get filterCommunicationVerified(): HealthCheckStatus {
    if (this.data.filterData === undefined) {
      return `checking`;
    }
    if (failable.isError(this.data.filterData)) {
      return `fail`;
    }
    return `ok`;
  }

  public get notificationsPermission(): HealthCheckStatus {
    switch (this.data.notificationsSetting) {
      case `alert`:
        return `ok`;
      case `banner`:
        return `warn`;
      case `none`:
        return `fail`;
      default:
        return `checking`;
    }
  }

  public get accountStatus(): HealthCheckStatus {
    if (this.data.accountStatus === undefined) {
      return `checking`;
    }
    if (failable.isError(this.data.accountStatus)) {
      return `errorDetermining`;
    }
    switch (this.data.accountStatus.value) {
      case `active`:
        return `ok`;
      case `needsAttention`:
        return `warn`;
      default:
        return `fail`;
    }
  }

  public get numFilterKeys(): HealthCheckStatus {
    if (this.data.filterData === undefined) {
      return `checking`;
    }
    if (failable.isError(this.data.filterData)) {
      return `errorDetermining`;
    }
    return this.data.filterData.value.numKeys === 0 ? `fail` : `ok`;
  }
}
