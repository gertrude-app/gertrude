import type { ActionOf } from '../lib/store';
import { Store } from '../lib/store';

export type RequestState<T = void, E = string> =
  | { case: `idle` }
  | { case: `ongoing` }
  | { case: `failed`; error?: E }
  | { case: `succeeded`; payload: T };

// begin codegen
export type OnboardingStep =
  | 'welcome'
  | 'wrongInstallDir'
  | 'confirmGertrudeAccount'
  | 'noGertrudeAccount'
  | 'macosUserAccountType'
  | 'getChildConnectionCode'
  | 'connectChild'
  | 'howToUseGifs'
  | 'allowNotifications_start'
  | 'allowNotifications_grant'
  | 'allowNotifications_failed'
  | 'allowFullDiskAccess_grantAndRestart'
  | 'allowFullDiskAccess_failed'
  | 'allowFullDiskAccess_success'
  | 'allowScreenshots_required'
  | 'allowScreenshots_grantAndRestart'
  | 'allowScreenshots_failed'
  | 'allowScreenshots_success'
  | 'allowKeylogging_required'
  | 'allowKeylogging_grant'
  | 'allowKeylogging_failed'
  | 'installSysExt_explain'
  | 'installSysExt_trick'
  | 'installSysExt_allow'
  | 'installSysExt_failed'
  | 'installSysExt_success'
  | 'appKeySelection_intro'
  | 'appKeySelection_blockApps'
  | 'appKeySelection_allowInternet'
  | 'optOutOfFiltering'
  | 'exemptUsers'
  | 'locateMenuBarIcon'
  | 'viewHealthCheck'
  | 'encourageFilterSuspensions'
  | 'screenTimeConflict'
  | 'howToUseGertrude'
  | 'finish';

export interface MacOSVersion {
  name: 'catalina' | 'bigSur' | 'monterey' | 'ventura' | 'sonoma' | 'sequoia' | 'tahoe';
  major: number;
}

export type UserRemediationStep =
  | 'create'
  | 'switch'
  | 'demote'
  | 'choose'
  | 'createForm'
  | 'createSuccess';

export interface MacOSUser {
  id: number;
  name: string;
  isAdmin: boolean;
}

export interface DiscoveredApp {
  name: string;
  bundleId: string;
  iconPath: string;
  category?: string;
}

export interface AppState {
  osVersion: {
    name: 'catalina' | 'bigSur' | 'monterey' | 'ventura' | 'sonoma' | 'sequoia' | 'tahoe';
    major: number;
  };
  windowOpen: boolean;
  step: OnboardingStep;
  userRemediationStep?: UserRemediationStep;
  logoutConfirmVisible: boolean;
  createUserRequest: RequestState;
  createdChildUser?: { fullName: string; username: string };
  currentUser?: MacOSUser;
  connectChildRequest: RequestState<string>;
  users: MacOSUser[];
  exemptableUserIds: number[];
  exemptUserIds: number[];
  discoveredApps: DiscoveredApp[];
  createAppKeysRequest: RequestState;
  isUpgrade: boolean;
}

export type AppEvent =
  | {
      case: 'createUserSubmitted';
      fullName: string;
      username: string;
      password: string;
      passwordHint?: string;
    }
  | { case: 'blockedAppsSelected'; bundleIds: string[] }
  | { case: 'appKeysSelected'; bundleIds: string[] }
  | { case: 'connectChildSubmitted'; code: number }
  | { case: 'infoModalOpened'; step: OnboardingStep; detail?: string }
  | { case: 'setUserExemption'; userId: number; enabled: boolean }
  | { case: 'closeWindow' }
  | { case: 'primaryBtnClicked' }
  | { case: 'secondaryBtnClicked' }
  | { case: 'chooseSwitchToNonAdminUserClicked' }
  | { case: 'chooseCreateNonAdminClicked' }
  | { case: 'chooseDemoteAdminClicked' }
  | { case: 'logoutConfirmClicked' }
  | { case: 'logoutConfirmCanceled' }
  | { case: 'createUserCanceled' }
  | { case: 'postCreateLogoutClicked' }
  | { case: 'postCreateSkipClicked' };
// end codegen

export type ViewState = {
  connectionCode: string;
  receivedAppState: boolean;
  didResume: boolean;
  blockedBundleIds: string[];
};
export type ViewAction = { type: `connectionCodeUpdated`; code: string };

export type Action = ActionOf<AppState, AppEvent, ViewAction>;
export type State = AppState & ViewState;

export class OnboardingStore extends Store<AppState, AppEvent, ViewState, ViewAction> {
  initializer(): AppState & ViewState {
    return {
      windowOpen: false,
      osVersion: { name: `sequoia`, major: 15 },
      step: `welcome`,
      logoutConfirmVisible: false,
      createUserRequest: { case: `idle` },
      connectChildRequest: { case: `idle` },
      currentUser: undefined,
      users: [],
      exemptableUserIds: [],
      exemptUserIds: [],
      discoveredApps: [],
      createAppKeysRequest: { case: `idle` },
      connectionCode: ``,
      receivedAppState: false,
      didResume: false,
      blockedBundleIds: [],
      isUpgrade: false,
    };
  }

  reducer(
    state: AppState & ViewState,
    action: ActionOf<AppState, AppEvent, ViewAction>,
  ): AppState & ViewState {
    switch (action.type) {
      case `connectionCodeUpdated`:
        return { ...state, connectionCode: action.code };
      case `receivedUpdatedAppState`:
        return {
          ...state,
          ...action.appState,
          didResume:
            state.receivedAppState === false && action.appState.step !== `welcome`,
          receivedAppState: true,
        };
      case `appEventEmitted`:
        switch (action.event.case) {
          case `connectChildSubmitted`:
            return { ...state, connectionCode: `` };
          case `blockedAppsSelected`:
            return { ...state, blockedBundleIds: action.event.bundleIds };
          default:
            return state;
        }
      default:
        return state;
    }
  }
}

export default new OnboardingStore();
