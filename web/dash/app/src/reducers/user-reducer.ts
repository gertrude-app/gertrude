import { produce } from 'immer';
import { defaults } from '@dash/types';
import type { KeychainSummary, PlainTimeWindow, User } from '@dash/types';
import { commit, editable } from '../lib/helpers';

type State = {
  user?: Editable<User>;
  addingKeychain?: KeychainSummary | null;
};

export type Action =
  | { type: 'setUser'; user: User; new?: boolean }
  | { type: 'setName'; name: string }
  | { type: 'userSaved' }
  | { type: 'setScreenshotsEnabled'; enabled: boolean }
  | { type: 'setScreenshotsResolution'; resolution: number }
  | { type: 'setScreenshotsFrequency'; frequency: number }
  | { type: 'setKeyloggingEnabled'; enabled: boolean }
  | { type: 'setDowntimeEnabled'; enabled: boolean }
  | { type: 'setDowntime'; downtime: PlainTimeWindow }
  | { type: 'setShowSuspensionActivity'; show: boolean }
  | { type: 'removeKeychain'; id: UUID }
  | { type: 'addKeychain'; keychain: KeychainSummary }
  | { type: 'setAddingKeychain'; keychain?: KeychainSummary | null };

function reducer(state: State, action: Action): State | undefined {
  if (action.type === `setUser`) {
    state.user = editable(action.user, action.new);
    return;
  } else if (action.type === `setAddingKeychain`) {
    state.addingKeychain = action.keychain;
    return;
  } else if (!state.user) {
    return;
  }
  switch (action.type) {
    case `userSaved`:
      state.user.isNew = false;
      state.user = commit(state.user);
      return;

    case `setName`:
      state.user.draft.name = action.name;
      return;
    case `setKeyloggingEnabled`:
      state.user.draft.keyloggingEnabled = action.enabled;
      return;
    case `setScreenshotsEnabled`:
      state.user.draft.screenshotsEnabled = action.enabled;
      return;
    case `setScreenshotsResolution`:
      state.user.draft.screenshotsResolution = action.resolution;
      return;
    case `setScreenshotsFrequency`:
      state.user.draft.screenshotsFrequency = action.frequency;
      return;
    case `setShowSuspensionActivity`:
      state.user.draft.showSuspensionActivity = action.show;
      return;
    case `removeKeychain`:
      state.user.draft.keychains = state.user.draft.keychains.filter(
        (keychain) => keychain.id !== action.id,
      );
      return;
    case `addKeychain`:
      state.user.draft.keychains.push(action.keychain);
      return;
    case `setDowntimeEnabled`:
      state.user.draft.downtime = action.enabled ? defaults.timeWindow() : undefined;
      return;
    case `setDowntime`:
      state.user.draft.downtime = action.downtime;
      return;
  }
}

export default produce(reducer);
