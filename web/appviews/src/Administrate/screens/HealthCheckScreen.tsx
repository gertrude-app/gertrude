import { Button } from '@shared/components';
import cx from 'classnames';
import React from 'react';
import type { HealthCheck, HealthCheckAction } from '../administrate-store';
import HealthCheckItem from '../subcomponents/HealthCheckItem';
import HealthChecker from '../HealthChecker';
import { value, errorMessage } from '../../lib/failable';

type Props = HealthCheck & {
  screenshotMonitoringEnabled: boolean;
  keystrokeMonitoringEnabled: boolean;
  installedAppVersion: string;
  emit(action: HealthCheckAction): unknown;
};

const HealthCheckScreen: React.FC<Props> = (props) => {
  const {
    latestAppVersion,
    filterData,
    installedAppVersion,
    accountStatus,
    screenshotMonitoringEnabled,
    keystrokeMonitoringEnabled,
    macOsUserType,
    emit,
  } = props;
  const health = new HealthChecker(
    props,
    installedAppVersion,
    screenshotMonitoringEnabled,
    keystrokeMonitoringEnabled,
  );
  return (
    <div className="h-full overflow-y-scroll appview:overflow-y-auto relative">
      <header className="flex items-center justify-between border-b p-4 border-slate-200 dark:border-slate-800 sticky bg-white dark:bg-slate-900 top-0 z-10">
        <div>
          <h2 className="text-2xl font-bold text-slate-800 dark:text-slate-100">
            Health check
          </h2>
          <span
            className={cx(
              `text-slate-600 dark:text-slate-400`,
              health.isChecking && `italic opacity-50`,
            )}
          >
            {health.isChecking
              ? `Checking...`
              : health.failingChecksCount
              ? `${health.failingChecksCount} failing checks`
              : `Everything looks good!`}
          </span>
        </div>
        <Button
          type="button"
          onClick={() => emit(`recheckClicked`)}
          disabled={health.isChecking}
          color="secondary"
          size="small"
        >
          <i
            className={cx(`fa-solid fa-sync mr-2`, health.isChecking && `animate-spin`)}
          />
          {health.isChecking ? `Checking...` : `Recheck`}
        </Button>
      </header>
      <ul className="flex flex-col space-y-2 p-4">
        <HealthCheckItem
          status={health.appVersion}
          title="App version"
          description={`You're up to date (${installedAppVersion})`}
          warnDescription={`Update available (${value(latestAppVersion)})`}
          failDescription={`Update required (${value(latestAppVersion)})`}
          errorDeterminingDescription={errorMessage(latestAppVersion)}
          actionLevel="warn"
          actionLabel="Update"
          actionIcon="sync"
          onAction={() => emit(`upgradeAppClicked`)}
        />
        <HealthCheckItem
          status={health.filterVersion}
          title="Filter version"
          description={`You're up to date (${value(latestAppVersion)})`}
          failDescription={`Update required (${value(latestAppVersion)})`}
          errorDeterminingDescription={errorMessage(filterData)}
          actionLabel="Update"
          actionIcon="sync"
          onAction={() => emit(`restartFilterClicked`)}
        />
        {screenshotMonitoringEnabled && (
          <HealthCheckItem
            status={health.screenRecordingPermission}
            title="Screen recording permission"
            description="Gertrude has the permission it needs"
            failDescription="Please grant Gertrude permission to record your screen"
            actionLabel="Fix permission"
            actionIcon="cog"
            onAction={() => emit(`fixScreenRecordingPermissionClicked`)}
          />
        )}
        {keystrokeMonitoringEnabled && (
          <HealthCheckItem
            status={health.keystrokeRecordingPermission}
            title="Keystroke recording permission"
            description="Gertrude has the permission it needs"
            failDescription="Please grant Gertrude permission to record your keystrokes"
            actionLabel="Fix permission"
            actionIcon="cog"
            onAction={() => emit(`fixKeystrokeRecordingPermissionClicked`)}
          />
        )}
        <HealthCheckItem
          status={health.macOsUserType}
          title="macOS user account type"
          errorDeterminingDescription={errorMessage(macOsUserType)}
          failDescription="Admin users can disable and uninstall Gertrude"
          actionLabel="Remove admin privilege"
          actionIcon="user"
          onAction={() => emit(`removeUserAdminPrivilegeClicked`)}
        />
        <HealthCheckItem
          status={health.filterCommunicationVerified}
          title="Filter to app communication"
          description="Verified"
          failDescription="Not verified"
          actionLabel="Restart filter"
          actionIcon="sync"
          onAction={() => emit(`repairFilterCommunicationClicked`)}
        />
        <HealthCheckItem
          status={health.notificationsPermission}
          title="Notification settings"
          description="Set to alert"
          warnDescription="Set to banner, recommended setting is alert"
          failDescription="Set to none, recommended setting is alert"
          actionLevel="warn"
          actionLabel="Fix permission"
          actionIcon="cog"
          onAction={() => emit(`fixNotificationPermissionClicked`)}
        />
        <HealthCheckItem
          status={health.accountStatus}
          title="Gertrude account status"
          description={`Current status: ${value(accountStatus)}`}
          warnDescription="Account needs attention"
          failDescription="Log in to the Gertrude parent admin website to resolve"
          errorDeterminingDescription={errorMessage(accountStatus)}
          actionLevel="never"
          actionLabel=""
          actionIcon=""
          onAction={() => {}}
        />
        <HealthCheckItem
          status={health.numFilterKeys}
          title="Filter rules"
          description={`Looks good, ${value(filterData)?.numKeys ?? 0} keys loaded`}
          failDescription="No keys loaded, try refreshing rules"
          errorDeterminingDescription={errorMessage(filterData)}
          actionLevel="warn"
          actionLabel="Refresh rules"
          actionIcon="sync"
          onAction={() => emit(`zeroKeysRefreshRulesClicked`)}
        />
      </ul>
    </div>
  );
};

export default HealthCheckScreen;
