import type { ActionOf } from '../lib/store';
import { Store } from '../lib/store';

// begin codegen
export type FilterState =
  | { case: 'suspended'; resuming: string }
  | { case: 'off' }
  | { case: 'on' };

export type AppState =
  | { case: 'connectionFailed'; error: string }
  | { case: 'connectionSucceded'; userName: string }
  | {
      case: 'connected';
      filterState: FilterState;
      recordingScreen: boolean;
      recordingKeystrokes: boolean;
    }
  | { case: 'notConnected' }
  | { case: 'enteringConnectionCode' }
  | { case: 'connecting' };

export type AppEvent =
  | { case: 'connectSubmit'; code: number }
  | { case: 'menuBarIconClicked' }
  | { case: 'resumeFilterClicked' }
  | { case: 'suspendFilterClicked' }
  | { case: 'refreshRulesClicked' }
  | { case: 'administrateClicked' }
  | { case: 'viewNetworkTrafficClicked' }
  | { case: 'connectClicked' }
  | { case: 'retryConnectClicked' }
  | { case: 'connectFailedHelpClicked' }
  | { case: 'welcomeAdminClicked' }
  | { case: 'turnOnFilterClicked' };
// end codegen

export type ViewState = {
  connectionCode: string;
};

export type ViewAction = {
  type: 'connectionCodeUpdated';
  code: string;
};

export type Action = ActionOf<AppState, AppEvent, ViewAction>;
export type State = AppState & ViewState;

export class MenuBarStore extends Store<AppState, AppEvent, ViewState, ViewAction> {
  initializer(): State {
    return { case: `notConnected`, connectionCode: `` };
  }

  reducer(state: State, action: Action): State {
    switch (action.type) {
      case `receivedUpdatedAppState`:
        return { ...state, ...action.appState };
      case `connectionCodeUpdated`:
        return { ...state, connectionCode: action.code };
      case `appEventEmitted`:
        switch (action.event.case) {
          case `connectSubmit`:
            return { ...state, connectionCode: `` };
          default:
            return state;
        }
    }
  }
}

export default new MenuBarStore();
