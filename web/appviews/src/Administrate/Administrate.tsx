import React from 'react';
import type { AppEvent, AppState, ViewState, ViewAction } from './administrate-store';
import type { PropsOf } from '../lib/store';
import { containerize } from '../lib/store';
import SidebarNav from './subcomponents/SidebarNav';
import HomeScreen from './screens/HomeScreen';
import HealthCheckScreen from './screens/HealthCheckScreen';
import ExemptUsersScreen from './screens/ExemptUsersScreen';
import HealthChecker from './HealthChecker';
import store from './administrate-store';

type Props = PropsOf<AppState, ViewState, AppEvent, ViewAction>;

export const Administrate: React.FC<Props> = ({
  healthCheck,
  filterState,
  userName,
  screenshotMonitoringEnabled,
  keystrokeMonitoringEnabled,
  installedAppVersion,
  emit,
  screen,
}) => {
  const health = new HealthChecker(
    healthCheck,
    installedAppVersion,
    screenshotMonitoringEnabled,
    keystrokeMonitoringEnabled,
  );

  let pageElement = (
    <HomeScreen
      setScreen={() => emit({ case: `gotoScreenClicked`, screen })}
      filterState={filterState}
      failingChecksCount={health.failingChecksCount}
      appVersion={installedAppVersion}
      userName={userName}
      keystrokeMonitoringEnabled={keystrokeMonitoringEnabled}
      screenshotMonitoringEnabled={screenshotMonitoringEnabled}
    />
  );

  switch (screen) {
    case `home`:
      pageElement = (
        <HomeScreen
          setScreen={() => emit({ case: `gotoScreenClicked`, screen: `home` })}
          filterState={filterState}
          failingChecksCount={health.failingChecksCount}
          appVersion={installedAppVersion}
          userName={userName}
          keystrokeMonitoringEnabled={keystrokeMonitoringEnabled}
          screenshotMonitoringEnabled={screenshotMonitoringEnabled}
        />
      );
      break;
    case `healthCheck`:
      pageElement = (
        <HealthCheckScreen
          {...healthCheck}
          installedAppVersion={installedAppVersion}
          screenshotMonitoringEnabled={keystrokeMonitoringEnabled}
          keystrokeMonitoringEnabled={screenshotMonitoringEnabled}
          emit={(action) => emit({ case: `healthCheck`, action })}
        />
      );
      break;
    case `exemptUsers`:
      pageElement = <ExemptUsersScreen />;
      break;
  }

  return (
    <div className="flex h-full appview:h-screen">
      <SidebarNav
        screen={screen}
        setScreen={(screen) => emit({ case: `gotoScreenClicked`, screen })}
      />
      <main className="flex-grow bg-white dark:bg-slate-900 rounded-br-xl">
        {pageElement}
      </main>
    </div>
  );
};

export default containerize<AppState, AppEvent, ViewState, ViewAction>(
  store,
  Administrate,
);
