import type { ActionOf } from '../lib/store';
import type { Failable } from '../lib/failable';
import type { AdminAccountStatus, FilterState } from '../lib/shared-types';
import { Store } from '../lib/store';

// begin codegen
export type Screen = 'home' | 'healthCheck' | 'exemptUsers' | 'advanced';

export type HealthCheck = {
  latestAppVersion?: { case: 'ok'; value: string } | { case: 'error'; message?: string };
  filterStatus?:
    | { case: 'installed'; version: string; numUserKeys: number }
    | { case: 'installing' }
    | { case: 'installTimeout' }
    | { case: 'notInstalled' }
    | { case: 'unexpected' }
    | { case: 'communicationBroken' };
  accountStatus?: Failable<AdminAccountStatus>;
  screenRecordingPermissionOk?: boolean;
  keystrokeRecordingPermissionOk?: boolean;
  macOsUserType?:
    | { case: 'ok'; value: 'admin' | 'standard' }
    | { case: 'error'; message?: string };
  notificationsSetting?: 'none' | 'banner' | 'alert';
};

export type ExemptableUser = {
  id: number;
  name: string;
  isAdmin: boolean;
  isExempt: boolean;
};

export type HealthCheckAction =
  | 'recheckClicked'
  | 'upgradeAppClicked'
  | 'installFilterClicked'
  | 'repairFilterCommunicationClicked'
  | 'repairOutOfDateFilterClicked'
  | 'fixScreenRecordingPermissionClicked'
  | 'fixKeystrokeRecordingPermissionClicked'
  | 'removeUserAdminPrivilegeClicked'
  | 'fixNotificationPermissionClicked'
  | 'zeroKeysRefreshRulesClicked';

export type AdvancedState = {
  pairqlEndpointOverride?: string;
  pairqlEndpointDefault: string;
  websocketEndpointOverride?: string;
  websocketEndpointDefault: string;
  appcastEndpointOverride?: string;
  appcastEndpointDefault: string;
  appVersions?: { [key: string]: string };
};

export type AdvancedAction =
  | { case: 'pairqlEndpointSet'; url?: string }
  | { case: 'websocketEndpointSet'; url?: string }
  | { case: 'appcastEndpointSet'; url?: string }
  | { case: 'forceUpdateToSpecificVersionClicked'; version: string }
  | { case: 'deleteAllDeviceStorageClicked' };

export type AppState = {
  windowOpen: boolean;
  screen: Screen;
  healthCheck: HealthCheck;
  filterState: FilterState;
  userName: string;
  screenshotMonitoringEnabled: boolean;
  keystrokeMonitoringEnabled: boolean;
  installedAppVersion: string;
  releaseChannel: 'stable' | 'beta' | 'canary';
  quitting: boolean;
  exemptableUsers?: Failable<ExemptableUser[]>;
  advanced?: AdvancedState;
};

export type AppEvent =
  | { case: 'healthCheck'; healthCheckAction: HealthCheckAction }
  | { case: 'advanced'; advancedAction: AdvancedAction }
  | { case: 'gotoScreenClicked'; screen: Screen }
  | { case: 'releaseChannelUpdated'; channel: 'stable' | 'beta' | 'canary' }
  | { case: 'suspendFilterClicked'; durationInSeconds: number }
  | { case: 'setUserExemption'; userId: number; enabled: boolean }
  | { case: 'closeWindow' }
  | { case: 'stopFilterClicked' }
  | { case: 'startFilterClicked' }
  | { case: 'resumeFilterClicked' }
  | { case: 'reinstallAppClicked' }
  | { case: 'quitAppClicked' }
  | { case: 'reconnectUserClicked' }
  | { case: 'administrateOSUserAccountsClicked' }
  | { case: 'checkForAppUpdatesClicked' }
  | { case: 'inactiveAccountRecheckClicked' }
  | { case: 'inactiveAccountDisconnectAppClicked' };
// end codegen

export type ViewState = {
  filterSuspensionDurationInSeconds: string;
};

export type ViewAction = {
  type: 'filterSuspensionDurationInSecondsChanged';
  value: string;
};

export type Action = ActionOf<AppState, AppEvent, ViewAction>;
export type State = AppState & ViewState;

export class AdministrateStore extends Store<AppState, AppEvent, ViewState, ViewAction> {
  appState(): AppState {
    return {
      windowOpen: true,
      screen: `home`,
      filterState: { case: `off` },
      userName: ``,
      installedAppVersion: `0.0.0`,
      screenshotMonitoringEnabled: false,
      keystrokeMonitoringEnabled: false,
      healthCheck: {},
      releaseChannel: `stable`,
      quitting: false,
    };
  }

  viewState(): ViewState {
    return {
      filterSuspensionDurationInSeconds: String(60 * 5), // 5 minutes
    };
  }

  initializer(): State {
    return { ...this.appState(), ...this.viewState() };
  }

  reducer(state: State, action: Action): State {
    switch (action.type) {
      case `filterSuspensionDurationInSecondsChanged`:
        return { ...state, filterSuspensionDurationInSeconds: action.value };
      case `receivedUpdatedAppState`:
        return { ...state, ...action.appState };
      case `appEventEmitted`:
        return state;
    }
  }
}

export default new AdministrateStore();
