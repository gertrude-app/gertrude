import type { FilterState } from '../lib/shared-types';
import type { ActionOf } from '../lib/store';
import { Store } from '../lib/store';

// begin codegen
export type AppState =
  | { case: `notConnected`; filterInstalled: boolean }
  | { case: `connectionFailed`; error: string }
  | { case: `connectionSucceded`; userName: string }
  | {
      case: `connected`;
      filterState: FilterState;
      recordingScreen: boolean;
      recordingKeystrokes: boolean;
      adminAttentionRequired: boolean;
      updateStatus?: `available` | `nag` | `require`;
    }
  | { case: `enteringConnectionCode` }
  | { case: `connecting` };

export type AppEvent =
  | { case: `connectSubmit`; code: number }
  | { case: `pauseDowntimeClicked`; duration: `tenMinutes` | `oneHour` | `oneDay` }
  | { case: `menuBarIconClicked` }
  | { case: `resumeFilterClicked` }
  | { case: `suspendFilterClicked` }
  | { case: `refreshRulesClicked` }
  | { case: `administrateClicked` }
  | { case: `viewNetworkTrafficClicked` }
  | { case: `connectClicked` }
  | { case: `retryConnectClicked` }
  | { case: `removeFilterClicked` }
  | { case: `connectFailedHelpClicked` }
  | { case: `welcomeAdminClicked` }
  | { case: `turnOnFilterClicked` }
  | { case: `updateNagDismissClicked` }
  | { case: `updateNagUpdateClicked` }
  | { case: `updateRequiredUpdateClicked` }
  | { case: `quitForNowClicked` }
  | { case: `quitForUninstallClicked` }
  | { case: `resumeDowntimeClicked` };
// end codegen

export type ViewState = {
  connectionCode: string;
  showingNotConnectedActions: boolean;
  showingDowntimePauseDuration: boolean;
};

export type ViewAction =
  | { type: `connectionCodeUpdated`; code: string }
  | { type: `toggleShowingDowntimePauseDuration` }
  | { type: `toggleShowingNotConnectedActions` };

export type Action = ActionOf<AppState, AppEvent, ViewAction>;
export type State = AppState & ViewState;

export class MenuBarStore extends Store<AppState, AppEvent, ViewState, ViewAction> {
  initializer(): State {
    return {
      case: `notConnected`,
      filterInstalled: false,
      connectionCode: ``,
      showingNotConnectedActions: false,
      showingDowntimePauseDuration: false,
    };
  }

  reducer(state: State, action: Action): State {
    switch (action.type) {
      case `receivedUpdatedAppState`:
        return { ...state, ...action.appState };
      case `connectionCodeUpdated`:
        return { ...state, connectionCode: action.code };
      case `toggleShowingNotConnectedActions`:
        return {
          ...state,
          showingNotConnectedActions: !state.showingNotConnectedActions,
        };
      case `toggleShowingDowntimePauseDuration`:
        return {
          ...state,
          showingDowntimePauseDuration: !state.showingDowntimePauseDuration,
        };
      case `appEventEmitted`:
        switch (action.event.case) {
          case `pauseDowntimeClicked`:
            return { ...state, showingDowntimePauseDuration: false };
          case `connectSubmit`:
            return { ...state, connectionCode: `` };
          default:
            return state;
        }
    }
  }
}

export default new MenuBarStore();
