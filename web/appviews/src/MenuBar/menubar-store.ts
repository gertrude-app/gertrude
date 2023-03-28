import type { Action } from '../lib/store';
import { Store } from '../lib/store';

// begin codegen
export type FilterState =
  | { case: 'suspended'; expiration: string }
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

export class MenuBarStore extends Store<AppState, AppEvent, ViewState, ViewAction> {
  initializer(): AppState & ViewState {
    return { case: `notConnected`, connectionCode: `` };
  }

  reducer(
    state: AppState & ViewState,
    action: Action<AppState, ViewAction>,
  ): AppState & ViewState {
    switch (action.type) {
      case `receivedUpdatedAppState`:
        return { ...state, ...action.appState };
      case `connectionCodeUpdated`:
        return { ...state, connectionCode: action.code };
    }
  }
}

export default new MenuBarStore();
