import type { Action } from '../lib/store';
import { Store } from '../lib/store';

// begin codegen
export type FilterState =
  | { case: 'suspended'; expiration: string }
  | { case: 'off' }
  | { case: 'on' };

export type AppState =
  | {
      case: 'connected';
      recordingKeystrokes: boolean;
      recordingScreen: boolean;
      filterState: FilterState;
    }
  | { case: 'notConnected' };

export type AppEvent =
  | 'fakeConnect'
  | 'menuBarIconClicked'
  | 'resumeFilterClicked'
  | 'suspendFilterClicked'
  | 'refreshRulesClicked'
  | 'administrateClicked'
  | 'viewNetworkTrafficClicked';
// end codegen

export type Props = AppState & {
  onResumeFilterClicked(): unknown;
  onSuspendFilterClicked(): unknown;
  onRefreshRulesClicked(): unknown;
  onAdministrateClicked(): unknown;
  onViewNetworkTrafficClicked(): unknown;
  onConnectToUserClicked(): unknown;
};

export class MenuBarStore extends Store<AppState, AppEvent, Props> {
  initializer(): AppState {
    return { case: `notConnected` };
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
      onResumeFilterClicked: () => emit(`resumeFilterClicked`),
      onSuspendFilterClicked: () => emit(`suspendFilterClicked`),
      onRefreshRulesClicked: () => emit(`refreshRulesClicked`),
      onAdministrateClicked: () => emit(`administrateClicked`),
      onViewNetworkTrafficClicked: () => emit(`viewNetworkTrafficClicked`),
      onConnectToUserClicked: () => emit(`fakeConnect`),
    };
  }
}

export default new MenuBarStore();
