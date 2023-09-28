import type { ActionOf } from '../lib/store';
import { Store } from '../lib/store';

export type RequestState<T = void, E = string> =
  | { state: 'idle' }
  | { state: 'ongoing' }
  | { state: 'failed'; error?: E }
  | { state: 'succeeded'; payload: T };

// start fake codegen
export interface MacOSUser {
  id: number;
  name: string;
  isAdmin: boolean;
}

export type UserRemediationStep = 'create' | 'switch' | 'demote' | 'choose';

export type OnboardingStep =
  | 'welcome'
  | 'confirmGertrudeAccount'
  | 'noGertrudeAccount'
  | 'macosUserAccountType'
  | 'getChildConnectionCode'
  | 'connectChild'
  | 'allowNotifications_start'
  | 'allowNotifications_grant'
  | 'allowNotifications_failed'
  | 'allowScreenshots_required'
  | 'allowScreenshots_openSysSettings'
  | 'allowScreenshots_grantAndRestart'
  | 'allowScreenshots_success'
  | 'allowScreenshots_failed'
  | 'allowKeylogging_required'
  | 'allowKeylogging_openSysSettings'
  | 'allowKeylogging_grant'
  | 'allowKeylogging_failed'
  | 'installSysExt_explain'
  | 'installSysExt_allowInstall'
  | 'installSysExt_failed'
  | 'installSysExt_success'
  | 'locateMenuBarIcon'
  | 'viewHealthCheck'
  | 'howToUseGertrude'
  | 'finish';

export type OSGroup = 'catalina' | 'bigSurOrMonterey' | 'venturaOrLater';

export interface AppState {
  os: OSGroup;
  macOSUser: {
    current: MacOSUser;
    list: Array<MacOSUser>;
    remediationStep?: UserRemediationStep;
  };
  connectChildRequest: RequestState<string>;
  screenRecordingPermissionGranted: boolean;
  keyloggingPermissionGranted: boolean;
  step: OnboardingStep;
}

export type AppEvent =
  | { case: 'primaryBtnClicked' }
  | { case: 'secondaryBtnClicked' }
  | { case: 'chooseSwitchToNonAdminUserClicked' }
  | { case: 'chooseCreateNonAdminClicked' }
  | { case: 'chooseDemoteAdminClicked' }
  | { case: 'connectChildSubmitted'; code: number };
// end fake codegen

export type ViewState = { connectionCode: string };
export type ViewAction = { type: 'updateConnectionCode'; code: string };

export type Action = ActionOf<AppState, AppEvent, ViewAction>;
export type State = AppState & ViewState;

export class OnboardingStore extends Store<AppState, AppEvent, ViewState, ViewAction> {
  initializer(): AppState & ViewState {
    return {
      os: `venturaOrLater`,
      step: `welcome`,
      connectChildRequest: { state: `idle` },
      screenRecordingPermissionGranted: false,
      keyloggingPermissionGranted: false,
      macOSUser: {
        current: { id: 501, name: ``, isAdmin: false },
        list: [],
      },
      connectionCode: ``,
    };
  }

  reducer(
    state: AppState & ViewState,
    _action: ActionOf<AppState, AppEvent, ViewAction>,
  ): AppState & ViewState {
    return state;
  }
}

export default new OnboardingStore();
