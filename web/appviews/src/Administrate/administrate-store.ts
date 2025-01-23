import type { ActionOf } from '../lib/store';
import type { Failable } from '../lib/failable';
import type { AdminAccountStatus, FilterState } from '../lib/shared-types';
import { Store } from '../lib/store';

// begin codegen
export type Screen = 'healthCheck' | 'actions' | 'exemptUsers' | 'advanced';

export interface HealthCheck {
  latestAppVersion?: { case: 'ok'; value: string } | { case: 'error'; message?: string };
  filterStatus?:
    | { case: 'communicationBroken'; repairing: boolean }
    | { case: 'installed'; version: string; numUserKeys: number }
    | { case: 'installing' }
    | { case: 'installTimeout' }
    | { case: 'notInstalled' }
    | { case: 'disabled' }
    | { case: 'unexpected' };
  accountStatus?: Failable<AdminAccountStatus>;
  screenRecordingPermissionOk?: boolean;
  keystrokeRecordingPermissionOk?: boolean;
  fullDiskAccessPermissionOk?: boolean;
  macOsUserType?:
    | { case: 'ok'; value: 'admin' | 'standard' }
    | { case: 'error'; message?: string };
  notificationsSetting?: 'none' | 'banner' | 'alert';
}

export interface ExemptableUser {
  id: number;
  name: string;
  isAdmin: boolean;
  isExempt: boolean;
}

export type HealthCheckAction =
  | 'recheckClicked'
  | 'upgradeAppClicked'
  | 'installFilterClicked'
  | 'enableFilterClicked'
  | 'repairFilterCommunicationClicked'
  | 'repairOutOfDateFilterClicked'
  | 'fixScreenRecordingPermissionClicked'
  | 'fixKeystrokeRecordingPermissionClicked'
  | 'fixFullDiskAccessPermissionClicked'
  | 'removeUserAdminPrivilegeClicked'
  | 'fixNotificationPermissionClicked'
  | 'zeroKeysRefreshRulesClicked';

export interface AdvancedState {
  pairqlEndpointOverride?: string;
  pairqlEndpointDefault: string;
  websocketEndpointOverride?: string;
  websocketEndpointDefault: string;
  appcastEndpointOverride?: string;
  appcastEndpointDefault: string;
  appVersions?: { [key: string]: string };
  webviewDebugging: boolean;
}

export type AdvancedAction =
  | { case: 'pairqlEndpointSet'; url?: string }
  | { case: 'websocketEndpointSet'; url?: string }
  | { case: 'appcastEndpointSet'; url?: string }
  | { case: 'setWebviewDebugging'; enabled: boolean }
  | { case: 'forceUpdateToSpecificVersionClicked'; version: string }
  | { case: 'deleteAllDeviceStorageClicked' };

export interface AppState {
  windowOpen: boolean;
  screen: Screen;
  healthCheck: HealthCheck;
  filterState: FilterState;
  user?: {
    name: string;
    screenshotMonitoringEnabled: boolean;
    keystrokeMonitoringEnabled: boolean;
  };
  availableAppUpdate?: { semver: string; required: boolean };
  installedAppVersion: string;
  releaseChannel: 'stable' | 'beta' | 'canary';
  quitting: boolean;
  exemptableUsers?: Failable<ExemptableUser[]>;
  advanced?: AdvancedState;
}

export type AppEvent =
  | { case: 'healthCheck'; action: HealthCheckAction }
  | { case: 'advanced'; action: AdvancedAction }
  | { case: 'gotoScreenClicked'; screen: Screen }
  | { case: 'setUserExemption'; userId: number; enabled: boolean }
  | { case: 'closeWindow' }
  | { case: 'confirmStopFilterClicked' }
  | { case: 'confirmQuitAppClicked' }
  | { case: 'disconnectUserClicked' }
  | { case: 'administrateOSUserAccountsClicked' }
  | { case: 'updateAppNowClicked' }
  | { case: 'inactiveAccountRecheckClicked' }
  | { case: 'inactiveAccountDisconnectAppClicked' };
// end codegen

export type ViewState = {
  filterSuspensionDurationInSeconds: string;
  dangerZoneModal: 'hidden' | 'stopFilter' | 'quitApp';
};

export type ViewAction =
  | { type: 'filterSuspensionDurationInSecondsChanged'; value: string }
  | { type: 'dangerZoneModalDismissed' }
  | { type: 'dangerZoneStopFilterClicked' }
  | { type: 'dangerZoneQuitAppClicked' };

export type Action = ActionOf<AppState, AppEvent, ViewAction>;
export type State = AppState & ViewState;

export class AdministrateStore extends Store<AppState, AppEvent, ViewState, ViewAction> {
  appState(): AppState {
    return {
      windowOpen: true,
      screen: `healthCheck`,
      filterState: { case: `off` },
      installedAppVersion: `0.0.0`,
      healthCheck: {},
      releaseChannel: `stable`,
      quitting: false,
    };
  }

  viewState(): ViewState {
    return {
      filterSuspensionDurationInSeconds: String(60 * 5), // 5 minutes
      dangerZoneModal: `hidden`,
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
      case `dangerZoneStopFilterClicked`:
        return { ...state, dangerZoneModal: `stopFilter` };
      case `dangerZoneQuitAppClicked`:
        return { ...state, dangerZoneModal: `quitApp` };
      case `dangerZoneModalDismissed`:
        return { ...state, dangerZoneModal: `hidden` };
      case `appEventEmitted`:
        if (action.event.case === `confirmStopFilterClicked`) {
          return { ...state, dangerZoneModal: `hidden` };
        }
        return state;
    }
  }
}

export default new AdministrateStore();
