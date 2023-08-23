import React from 'react';
import cx from 'classnames';
import type { AppEvent, AppState, ViewState, ViewAction } from './administrate-store';
import type { PropsOf } from '../lib/store';
import { valueOf } from '../lib/failable';
import { containerize } from '../lib/store';
import InactiveAccountScreen from '../components/InactiveAccountBlock';
import SidebarNav from './subcomponents/SidebarNav';
import ActionsScreen from './screens/ActionsScreen';
import HealthCheckScreen from './screens/HealthCheckScreen';
import ExemptUsersScreen from './screens/ExemptUsersScreen';
import HiddenAdvancedScreen from './screens/HiddenAdvancedScreen';
import store from './administrate-store';

type Props = PropsOf<AppState, ViewState, AppEvent, ViewAction>;

export const Administrate: React.FC<Props> = ({
  healthCheck,
  filterState,
  user,
  installedAppVersion,
  availableAppUpdate,
  releaseChannel,
  exemptableUsers,
  screen,
  advanced,
  quitting,
  dangerZoneModal,
  emit,
  dispatch,
}) => {
  let pageElement: JSX.Element;

  switch (screen) {
    case `healthCheck`:
      pageElement = (
        <HealthCheckScreen
          {...healthCheck}
          installedAppVersion={installedAppVersion}
          screenshotMonitoringEnabled={user?.keystrokeMonitoringEnabled ?? false}
          keystrokeMonitoringEnabled={user?.screenshotMonitoringEnabled ?? false}
          emit={(action) => emit({ case: `healthCheck`, action })}
        />
      );
      break;
    case `actions`:
      pageElement = (
        <ActionsScreen
          releaseChannel={releaseChannel}
          emit={emit}
          dispatch={dispatch}
          filterRunning={filterState.case === `on`}
          installedAppVersion={installedAppVersion}
          availableAppUpdate={availableAppUpdate}
          dangerZoneModal={dangerZoneModal}
          userName={user?.name}
          quitting={quitting}
        />
      );
      break;
    case `exemptUsers`:
      pageElement = <ExemptUsersScreen emit={emit} users={exemptableUsers} />;
      break;

    case `advanced`:
      pageElement = advanced ? (
        <HiddenAdvancedScreen
          {...advanced}
          emit={(action) => emit({ case: `advanced`, action })}
        />
      ) : (
        <>Loading...</>
      );
      break;
  }

  if (valueOf(healthCheck.accountStatus) === `inactive`) {
    return (
      <InactiveAccountScreen
        onRecheck={() => emit({ case: `inactiveAccountRecheckClicked` })}
        onDisconnect={() => emit({ case: `inactiveAccountDisconnectAppClicked` })}
      />
    );
  }

  return (
    <div className="flex flex-col h-screen">
      <div className={cx(`flex flex-grow relative`)}>
        <SidebarNav
          screen={screen}
          setScreen={(screen) => emit({ case: `gotoScreenClicked`, screen })}
        />
        <main className="flex-grow bg-white dark:bg-slate-900 ml-16">{pageElement}</main>
      </div>
    </div>
  );
};

export default containerize<AppState, AppEvent, ViewState, ViewAction>(
  store,
  Administrate,
);
