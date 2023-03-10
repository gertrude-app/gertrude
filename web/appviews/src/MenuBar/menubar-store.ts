import type { Action } from '../lib/store';
import { Store } from '../lib/store';

// begin codegen
export type FilterState =
  | { case: 'suspended'; expiration: string }
  | { case: 'off' }
  | { case: 'on' };

export type AppState = {
  connection:
    | { case: 'connectFailed'; connectFailed: string }
    | {
        case: 'connected';
        name: string;
        keyloggingEnabled: boolean;
        screenshotsEnabled: boolean;
      }
    | { case: 'notConnected' }
    | { case: 'enteringConnectionCode' }
    | { case: 'connecting' };
  filterState: FilterState;
};

export type AppEvent =
  | { case: 'connectSubmit'; code: number }
  | { case: 'menuBarIconClicked' }
  | { case: 'resumeFilterClicked' }
  | { case: 'suspendFilterClicked' }
  | { case: 'refreshRulesClicked' }
  | { case: 'administrateClicked' }
  | { case: 'viewNetworkTrafficClicked' }
  | { case: 'connectClicked' };
// end codegen

export type Props = AppState & {
  onResumeFilterClicked(): unknown;
  onSuspendFilterClicked(): unknown;
  onRefreshRulesClicked(): unknown;
  onAdministrateClicked(): unknown;
  onViewNetworkTrafficClicked(): unknown;
  onConnectClicked(): unknown;
  onConnectSubmit(code: number): unknown;
};

export class MenuBarStore extends Store<AppState, AppEvent, Props> {
  initializer(): AppState {
    return {
      connection: { case: `notConnected` },
      filterState: { case: `off` },
    };
  }

  reducer(state: AppState, action: Action<AppState>): AppState {
    switch (action.type) {
      case `receivedUpdatedAppState`:
        return action.appState;
    }
  }

  selector(state: AppState, emit: (event: AppEvent) => unknown): Props {
    return {
      ...state,
      onResumeFilterClicked: () => emit({ case: `resumeFilterClicked` }),
      onSuspendFilterClicked: () => emit({ case: `suspendFilterClicked` }),
      onRefreshRulesClicked: () => emit({ case: `refreshRulesClicked` }),
      onAdministrateClicked: () => emit({ case: `administrateClicked` }),
      onViewNetworkTrafficClicked: () => emit({ case: `viewNetworkTrafficClicked` }),
      onConnectClicked: () => emit({ case: `connectClicked` }),
      onConnectSubmit: (code: number) => emit({ case: `connectSubmit`, code }),
    };
  }
}

export default new MenuBarStore();
