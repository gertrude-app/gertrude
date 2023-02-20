import type { Action, Store } from '../lib/store';
import { BaseStore } from '../lib/store';

type State = AppState & { loading: boolean };

export class MenuBarStore
  extends BaseStore<State, AppEvent>
  implements Store<State, Action<AppState>, AppEvent, Props>
{
  initializer(): State {
    return { state: `notConnected`, loading: true };
  }

  reducer(state: State, _action: Action<AppState>): State {
    return state;
  }

  selector(
    _state: AppState,
    _dispatch: (action: Action<AppState>) => unknown,
    _emit: (event: AppEvent) => unknown,
  ): Props {
    return {
      state: `notConnected`,
      onResumeFilterClicked: () => {},
      onSuspendFilterClicked: () => {},
      onRefreshRulesClicked: () => {},
      onAdministrateClicked: () => {},
      onViewNetworkTrafficClicked: () => {},
    };
  }
}

const store = new MenuBarStore();
export default store;

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
  | 'viewNetworkTrafficClicked';

export type Props = AppState & {
  onResumeFilterClicked(): unknown;
  onSuspendFilterClicked(): unknown;
  onRefreshRulesClicked(): unknown;
  onAdministrateClicked(): unknown;
  onViewNetworkTrafficClicked(): unknown;
};
