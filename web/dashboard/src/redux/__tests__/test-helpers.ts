import { State } from '../store';
import { initialState as authInitialState } from '../slice-auth';
import { initialState as usersInitialState } from '../slice-users';
import { initialState as menuInitialState } from '../slice-menu';
import { initialState as signupInitialState } from '../slice-signup';
import { initialState as adminInitialState } from '../slice-admin';
import { initialState as keychainsInitialState } from '../slice-keychains';
import { initialState as urlInitialState } from '../slice-url';
import { initialState as appsInitialState } from '../slice-apps';
import { initialState as dashboardInitialState } from '../slice-dashboard';
import { initialState as unlockRequestsInitialState } from '../slice-unlock-requests';
import { initialState as filterSuspensionsInitialState } from '../slice-filter-suspensions';

export function makeState(mutator: (state: State) => unknown = () => {}): State {
  const state: State = {
    admin: adminInitialState(),
    apps: appsInitialState(),
    auth: authInitialState(),
    dashboard: dashboardInitialState(),
    keychains: keychainsInitialState(),
    menu: menuInitialState(),
    signup: signupInitialState(),
    filterSuspensions: filterSuspensionsInitialState(),
    users: usersInitialState(),
    unlockRequests: unlockRequestsInitialState(),
    url: urlInitialState(),
  };
  mutator(state);
  return state;
}

export function makeGetState(mutator: (state: State) => unknown = () => {}): () => State {
  return () => makeState(mutator);
}

export function nextTick(): Promise<unknown> {
  return new Promise<unknown>(setImmediate);
}
