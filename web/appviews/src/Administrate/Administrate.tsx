import React from 'react';
import type { AppEvent, AppState, ViewState, ViewAction } from './administrate-store';
import type { PropsOf } from '../lib/store';
import { containerize } from '../lib/store';
import WarningBanner from '../components/WarningBanner';
import InactiveAccountScreen from '../components/InactiveAccountBlock';
import SidebarNav from './subcomponents/SidebarNav';
import HomeScreen from './screens/HomeScreen';
import HealthCheckScreen from './screens/HealthCheckScreen';
import ExemptUsersScreen from './screens/ExemptUsersScreen';
import HealthChecker, { statusFromHealthCheck } from './HealthChecker';
import store from './administrate-store';

type Props = PropsOf<AppState, ViewState, AppEvent, ViewAction>;

export const Administrate: React.FC<Props> = ({
  healthCheck,
  filterState,
  userName,
  screenshotMonitoringEnabled,
  keystrokeMonitoringEnabled,
  filterSuspensionDurationInSeconds,
  installedAppVersion,
  releaseChannel,
  exemptableUsers,
  emit,
  dispatch,
  screen,
  quitting,
}) => {
  const health = new HealthChecker(
    healthCheck,
    installedAppVersion,
    screenshotMonitoringEnabled,
    keystrokeMonitoringEnabled,
  );
  const accountStatus = statusFromHealthCheck(healthCheck);

  let pageElement: JSX.Element;

  switch (screen) {
    case `home`:
      pageElement = (
        <HomeScreen
          dispatch={dispatch}
          filterSuspensionDurationInSeconds={filterSuspensionDurationInSeconds}
          releaseChannel={releaseChannel}
          emit={emit}
          setScreen={(screen) => emit({ case: `gotoScreenClicked`, screen })}
          filterState={filterState}
          failingChecksCount={health.failingChecksCount}
          appVersion={installedAppVersion}
          userName={userName}
          keystrokeMonitoringEnabled={keystrokeMonitoringEnabled}
          screenshotMonitoringEnabled={screenshotMonitoringEnabled}
          quitting={quitting}
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
      pageElement = <ExemptUsersScreen emit={emit} users={exemptableUsers} />;
      break;
  }

  if (accountStatus === `inactive`) {
    return <InactiveAccountScreen />;
  }

  return (
    <div className="flex flex-col h-full appview:h-screen">
      {(accountStatus === `error` || accountStatus === `needsAttention`) && (
        <div className="border-b border-slate-200 dark:border-slate-800 p-4 dark:bg-slate-900 bg-white">
          <WarningBanner
            severity={accountStatus === `needsAttention` ? `warning` : `error`}
          >
            {accountStatus === `needsAttention`
              ? `Your Gertrude account payment is past due! Login to the web admin dashboard before app loses functionality.`
              : `We've encountered an unknown account error. Please try restarting the app.`}
          </WarningBanner>
        </div>
      )}
      <div className="flex rounded-b-xl overflow-hidden flex-grow">
        <SidebarNav
          screen={screen}
          setScreen={(screen) => emit({ case: `gotoScreenClicked`, screen })}
        />
        <main className="flex-grow bg-white dark:bg-slate-900 rounded-br-xl">
          {pageElement}
        </main>
      </div>
    </div>
  );
};

export default containerize<AppState, AppEvent, ViewState, ViewAction>(
  store,
  Administrate,
);
