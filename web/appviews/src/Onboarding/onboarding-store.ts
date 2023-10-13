import type { ActionOf } from '../lib/store';
import { Store } from '../lib/store';

export type RequestState<T = void, E = string> =
  | { case: 'idle' }
  | { case: 'ongoing' }
  | { case: 'failed'; error?: E }
  | { case: 'succeeded'; payload: T };

// begin codegen
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
  | 'allowScreenshots_grantAndRestart'
  | 'allowScreenshots_failed'
  | 'allowScreenshots_success'
  | 'allowKeylogging_required'
  | 'allowKeylogging_openSysSettings'
  | 'allowKeylogging_grant'
  | 'allowKeylogging_failed'
  | 'installSysExt_explain'
  | 'installSysExt_allow'
  | 'installSysExt_failed'
  | 'installSysExt_success'
  | 'locateMenuBarIcon'
  | 'viewHealthCheck'
  | 'howToUseGertrude'
  | 'finish';

export type OSGroup = 'catalina' | 'bigSurOrMonterey' | 'venturaOrLater';

export type UserRemediationStep = 'create' | 'switch' | 'demote' | 'choose';

export interface MacOSUser {
  id: number;
  name: string;
  isAdmin: boolean;
}

export interface AppState {
  os: OSGroup;
  windowOpen: boolean;
  step: OnboardingStep;
  userRemediationStep?: UserRemediationStep;
  currentUser?: MacOSUser;
  connectChildRequest: RequestState<string>;
  users: MacOSUser[];
}

export type AppEvent =
  | { case: 'connectChildSubmitted'; code: number }
  | { case: 'infoModalOpened'; step: OnboardingStep; detail?: string }
  | { case: 'closeWindow' }
  | { case: 'primaryBtnClicked' }
  | { case: 'secondaryBtnClicked' }
  | { case: 'chooseSwitchToNonAdminUserClicked' }
  | { case: 'chooseCreateNonAdminClicked' }
  | { case: 'chooseDemoteAdminClicked' };
// end codegen

export type ViewState = { connectionCode: string };
export type ViewAction = { type: 'connectionCodeUpdated'; code: string };

export type Action = ActionOf<AppState, AppEvent, ViewAction>;
export type State = AppState & ViewState;

export class OnboardingStore extends Store<AppState, AppEvent, ViewState, ViewAction> {
  initializer(): AppState & ViewState {
    return {
      windowOpen: false,
      os: `venturaOrLater`,
      step: `welcome`,
      connectChildRequest: { case: `idle` },
      currentUser: { id: 501, name: ``, isAdmin: false },
      users: [],
      connectionCode: ``,
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
        return { ...state, ...action.appState };
      case `appEventEmitted`:
        switch (action.event.case) {
          case `connectChildSubmitted`:
            return { ...state, connectionCode: `` };
          default:
            return state;
        }
      default:
        return state;
    }
  }
}

export default new OnboardingStore();
