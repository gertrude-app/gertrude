import { Button } from '@shared/components';
import React from 'react';
import { HealthCheckStatus } from '../Administrate';
import HealthCheckItem from '../subcomponents/HealthCheckItem';

interface Props {
  healthCheck: HealthCheckStatus;
  failingChecksCount: number;
}

const HealthCheckScreen: React.FC<Props> = ({ healthCheck, failingChecksCount }) => {
  return (
    <div className="h-full p-4 overflow-scroll">
      <header className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-slate-800 dark:text-slate-100">
            Health check
          </h2>
          <span className="text-slate-600 dark:text-slate-400">
            {failingChecksCount
              ? `${failingChecksCount} failing checks`
              : `Everything looks good!`}
          </span>
        </div>
        <Button type="button" onClick={() => {}} color="secondary" size="small">
          <i className="fa-solid fa-sync mr-2" />
          Recheck
        </Button>
      </header>
      <ul className="mt-6 flex flex-col space-y-2">
        <HealthCheckItem
          status={
            healthCheck.appVersion === healthCheck.mostRecentAppVersion
              ? 'good'
              : 'warning'
          }
          title={'App version'}
          description={
            healthCheck.appVersion === healthCheck.mostRecentAppVersion
              ? `You're up to date (${healthCheck.appVersion})`
              : `Update available (${healthCheck.mostRecentAppVersion})`
          }
          action={
            healthCheck.appVersion !== healthCheck.mostRecentAppVersion
              ? {
                  onClick: () => {},
                  label: 'Update',
                  icon: 'sync',
                }
              : undefined
          }
        />
        <HealthCheckItem
          status={
            healthCheck.filterVersion === healthCheck.mostRecentFilterVersion
              ? 'good'
              : 'warning'
          }
          title={'Filter version'}
          description={
            healthCheck.filterVersion === healthCheck.mostRecentFilterVersion
              ? `You're up to date (${healthCheck.filterVersion})`
              : `Update available (${healthCheck.mostRecentFilterVersion})`
          }
          action={
            healthCheck.filterVersion !== healthCheck.mostRecentFilterVersion
              ? {
                  onClick: () => {},
                  label: 'Update',
                  icon: 'sync',
                }
              : undefined
          }
        />
        <HealthCheckItem
          status={healthCheck.screenRecordingPermission ? 'good' : 'bad'}
          title={'Screen recording permission'}
          description={
            healthCheck.screenRecordingPermission
              ? 'Gertrude has the permission it needs'
              : 'Please grant Gertrude permission to record your screen'
          }
          action={
            !healthCheck.screenRecordingPermission
              ? { label: 'Fix permission', onClick: () => {}, icon: 'cog' }
              : undefined
          }
        />
        <HealthCheckItem
          status={healthCheck.keystrokeRecordingPermission ? 'good' : 'bad'}
          title={'Keystroke recording permission'}
          description={
            healthCheck.keystrokeRecordingPermission
              ? 'Gertrude has the permission it needs'
              : 'Please grant Gertrude permission to record your keystrokes'
          }
          action={
            !healthCheck.keystrokeRecordingPermission
              ? { label: 'Fix permission', onClick: () => {}, icon: 'cog' }
              : undefined
          }
        />
        <HealthCheckItem
          status={healthCheck.isAdministrator ? 'bad' : 'good'}
          title={'macOS user account type'}
          action={
            healthCheck.isAdministrator
              ? {
                  label: 'Remove user administrator privilege',
                  onClick: () => {},
                  icon: 'user',
                }
              : undefined
          }
        />
        <HealthCheckItem
          status={healthCheck.filterToAppCommunicationVerified ? 'good' : 'bad'}
          title={'Filter to app communication'}
          description={
            healthCheck.filterToAppCommunicationVerified ? 'Verified' : 'Not verified'
          }
          action={
            !healthCheck.filterToAppCommunicationVerified
              ? {
                  label: 'Do something',
                  onClick: () => {},
                  icon: 'exclamation',
                }
              : undefined
          }
        />
        <HealthCheckItem
          status={(() => {
            switch (healthCheck.notificationSetting) {
              case 'alert':
                return 'good';
              case 'banners':
                return 'warning';
              case 'none':
                return 'bad';
            }
          })()}
          title={'Notification settings'}
          description={
            healthCheck.notificationSetting === 'alert'
              ? 'Set to "alert"'
              : `Set to "${healthCheck.notificationSetting}", recommended setting is "alert"`
          }
          action={
            healthCheck.notificationSetting !== 'alert'
              ? {
                  label: 'Fix permission',
                  onClick: () => {},
                  icon: 'cog',
                }
              : undefined
          }
        />
        <HealthCheckItem
          status={healthCheck.accountStatus === 'active' ? 'good' : 'bad'}
          title={'Gertrude account status'}
          description={`Current status: ${healthCheck.accountStatus}`}
          action={
            healthCheck.accountStatus !== 'active'
              ? {
                  label: 'Fix it',
                  onClick: () => {},
                  icon: 'exclamation',
                }
              : undefined
          }
        />
        <HealthCheckItem
          status={healthCheck.keysLoaded ? 'good' : 'bad'}
          title={'Filter rules'}
          description={
            healthCheck.keysLoaded
              ? `Looks good, ${healthCheck.keysLoaded} keys loaded`
              : 'No keys loaded'
          }
          action={
            !healthCheck.keysLoaded
              ? {
                  label: 'Fix it',
                  onClick: () => {},
                  icon: 'exclamation',
                }
              : undefined
          }
        />
      </ul>
    </div>
  );
};

export default HealthCheckScreen;
