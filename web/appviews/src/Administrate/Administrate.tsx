import React from 'react';
import SidebarNav from './subcomponents/SidebarNav';
import HomeScreen from './screens/HomeScreen';
import HealthCheckScreen from './screens/HealthCheckScreen';
import ExemptUsersScreen from './screens/ExemptUsersScreen';

export type Page = 'home' | 'health_check' | 'exempt_users';
export type HealthCheckStatus = {
  appVersion: string;
  mostRecentAppVersion: string;
  filterVersion: string;
  mostRecentFilterVersion: string;
  screenRecordingPermission: boolean;
  keystrokeRecordingPermission: boolean;
  isAdministrator: boolean;
  filterToAppCommunicationVerified: boolean;
  notificationSetting: 'banners' | 'alert' | 'none';
  accountStatus: 'active' | 'inactive';
  keysLoaded: number;
};

interface Props {
  healthCheck: HealthCheckStatus;
  filterStatus: 'on' | 'off' | 'suspended';
  userName: string;
  screenshotMonitoringEnabled: boolean;
  keystrokeMonitoringEnabled: boolean;
}

const Administrate: React.FC<Props> = ({
  healthCheck,
  filterStatus,
  userName,
  screenshotMonitoringEnabled,
  keystrokeMonitoringEnabled,
}) => {
  const [page, setPage] = React.useState<Page>(`home`);

  const failingChecksCount = [
    healthCheck.appVersion === healthCheck.mostRecentAppVersion,
    healthCheck.filterVersion === healthCheck.mostRecentFilterVersion,
    healthCheck.screenRecordingPermission,
    healthCheck.keystrokeRecordingPermission,
    healthCheck.filterToAppCommunicationVerified,
    healthCheck.notificationSetting === `alert`,
    healthCheck.accountStatus === `active`,
    healthCheck.keysLoaded > 0,
  ].filter((item) => !item).length;

  let pageElement = (
    <HomeScreen
      page={page}
      setPage={setPage}
      filterStatus={filterStatus}
      failingChecksCount={failingChecksCount}
      appVersion={healthCheck.appVersion}
      userName={userName}
      keystrokeMonitoringEnabled={keystrokeMonitoringEnabled}
      screenshotMonitoringEnabled={screenshotMonitoringEnabled}
    />
  );

  switch (page) {
    case `home`:
      pageElement = (
        <HomeScreen
          page={page}
          setPage={setPage}
          filterStatus={filterStatus}
          failingChecksCount={failingChecksCount}
          appVersion={healthCheck.appVersion}
          userName={userName}
          keystrokeMonitoringEnabled={keystrokeMonitoringEnabled}
          screenshotMonitoringEnabled={screenshotMonitoringEnabled}
        />
      );
      break;
    case `health_check`:
      pageElement = (
        <HealthCheckScreen
          healthCheck={healthCheck}
          failingChecksCount={failingChecksCount}
        />
      );
      break;
    case `exempt_users`:
      pageElement = <ExemptUsersScreen />;
      break;
  }

  return (
    <div className="flex h-full">
      <SidebarNav page={page} setPage={setPage} />
      <main className="flex-grow bg-white dark:bg-slate-900 rounded-br-xl">
        {pageElement}
      </main>
    </div>
  );
};

export default Administrate;
