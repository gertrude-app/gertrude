import type { Action } from '../lib/store';
import { Store } from '../lib/store';

type FilterState =
  | { state: 'off' }
  | { state: 'on' }
  | { state: 'suspended'; expiration: string };

export type AppState =
  | { state: 'notConnected' }
  | {
      state: 'connected';
      recordingKeystrokes: boolean;
      recordingScreenshots: boolean;
      filterState: FilterState;
    };

type AppEvent =
  | 'resumeFilterClicked'
  | 'suspendFilterClicked'
  | 'refreshRulesClicked'
  | 'administrateClicked'
  | 'viewNetworkTrafficClicked'
  | 'fakeConnect';

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
    return { state: `notConnected` };
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
