import type { ActionOf } from '../lib/store';
import { Store } from '../lib/store';

// begin codegen
export type Screen = 'home' | 'healthCheck' | 'exemptUsers';

export type HealthCheck = {
  latestAppVersion?: { case: 'ok'; value: string } | { case: 'error'; message?: string };
  filterData?:
    | { case: 'ok'; value: { version: string; numKeys: number } }
    | { case: 'error'; message?: string };
  accountStatus?:
    | { case: 'ok'; value: 'active' | 'needsAttention' | 'inactive' }
    | { case: 'error'; message?: string };
  screenRecordingPermissionOk?: boolean;
  keystrokeRecordingPermissionOk?: boolean;
  macOsUserType?:
    | { case: 'ok'; value: 'standard' | 'admin' }
    | { case: 'error'; message?: string };
  notificationsSetting?: 'none' | 'banner' | 'alert';
};

export type HealthCheckAction =
  | 'recheckClicked'
  | 'upgradeAppClicked'
  | 'repairFilterCommunicationClicked'
  | 'restartFilterClicked'
  | 'fixScreenRecordingPermissionClicked'
  | 'fixKeystrokeRecordingPermissionClicked'
  | 'removeUserAdminPrivilegeClicked'
  | 'fixNotificationPermissionClicked'
  | 'zeroKeysRefreshRulesClicked';

export type AppState = {
  windowOpen: boolean;
  screen: Screen;
  healthCheck: HealthCheck;
  filterState: 'on' | 'off' | 'suspended';
  userName: string;
  screenshotMonitoringEnabled: boolean;
  keystrokeMonitoringEnabled: boolean;
  installedAppVersion: string;
};

export type AppEvent =
  | { case: 'healthCheck'; action: HealthCheckAction }
  | { case: 'gotoScreenClicked'; screen: Screen }
  | { case: 'closeWindow' };
// end codegen

export type ViewState = {}; // eslint-disable-line
export type ViewAction = never;
export type Action = ActionOf<AppState, AppEvent, ViewAction>;
export type State = AppState & ViewState;

export class AdministrateStore extends Store<AppState, AppEvent, ViewState, ViewAction> {
  appState(): AppState {
    return {
      windowOpen: true,
      screen: `home`,
      filterState: `off`,
      userName: ``,
      installedAppVersion: `0.0.0`,
      screenshotMonitoringEnabled: false,
      keystrokeMonitoringEnabled: false,
      healthCheck: {},
    };
  }

  viewState(): ViewState {
    return {};
  }

  initializer(): State {
    return { ...this.appState(), ...this.viewState() };
  }

  reducer(state: State, action: Action): State {
    switch (action.type) {
      case `receivedUpdatedAppState`:
        return { ...state, ...action.appState };
      case `appEventEmitted`:
        return state;
    }
  }
}

export default new AdministrateStore();
