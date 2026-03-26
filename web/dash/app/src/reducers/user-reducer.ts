import { defaults } from '@dash/types';
import { produce } from 'immer';
import { v4 as uuid } from 'uuid';
import type {
  Child,
  PlainTimeWindow,
  RuleSchedule,
  UserKeychainSummary,
} from '@dash/types';
import { commit, editable } from '../lib/helpers';

type State = {
  child?: Editable<Child>;
  addingKeychain?: UserKeychainSummary | null;
  newBlockedAppIdentifier?: string;
};

export type Action =
  | { type: `setChild`; child: Child; new?: boolean }
  | { type: `setName`; name: string }
  | { type: `childSaved` }
  | { type: `setScreenshotsEnabled`; enabled: boolean }
  | { type: `setScreenshotsResolution`; resolution: number }
  | { type: `setScreenshotsFrequency`; frequency: number }
  | { type: `setKeyloggingEnabled`; enabled: boolean }
  | { type: `setDowntimeEnabled`; enabled: boolean }
  | { type: `setDowntime`; downtime: PlainTimeWindow }
  | { type: `setShowSuspensionActivity`; show: boolean }
  | { type: `setFilteringDisabled`; disabled: boolean }
  | { type: `removeKeychain`; id: UUID }
  | { type: `updateNewBlockedAppIdentifier`; identifier: string }
  | { type: `removeBlockedApp`; id: UUID }
  | { type: `addNewBlockedApp` }
  | { type: `setBlockedAppSchedule`; id: UUID; schedule?: RuleSchedule }
  | { type: `setKeychainSchedule`; id: UUID; schedule?: RuleSchedule }
  | { type: `addKeychain`; keychain: UserKeychainSummary }
  | { type: `setAddingKeychainSchedule`; schedule?: RuleSchedule }
  | { type: `setAddingKeychain`; keychain?: UserKeychainSummary | null };

function reducer(state: State, action: Action): State | undefined {
  if (action.type === `setChild`) {
    state.child = editable(action.child, action.new);
    return;
  } else if (action.type === `setAddingKeychain`) {
    state.addingKeychain = action.keychain;
    return;
  } else if (!state.child) {
    return;
  }
  switch (action.type) {
    case `childSaved`:
      state.child.isNew = false;
      state.child = commit(state.child);
      return;
    case `setName`:
      state.child.draft.name = action.name;
      return;
    case `setKeyloggingEnabled`:
      state.child.draft.keyloggingEnabled = action.enabled;
      return;
    case `setScreenshotsEnabled`:
      state.child.draft.screenshotsEnabled = action.enabled;
      return;
    case `setScreenshotsResolution`:
      state.child.draft.screenshotsResolution = action.resolution;
      return;
    case `setScreenshotsFrequency`:
      state.child.draft.screenshotsFrequency = action.frequency;
      return;
    case `setShowSuspensionActivity`:
      state.child.draft.showSuspensionActivity = action.show;
      return;
    case `setFilteringDisabled`:
      state.child.draft.filteringDisabled = action.disabled;
      return;
    case `updateNewBlockedAppIdentifier`:
      state.newBlockedAppIdentifier = action.identifier;
      return;
    case `addNewBlockedApp`:
      if (state.newBlockedAppIdentifier) {
        state.child.draft.blockedApps = [
          ...(state.child.draft.blockedApps ?? []),
          { id: uuid(), identifier: state.newBlockedAppIdentifier },
        ];
        state.newBlockedAppIdentifier = ``;
      }
      return;
    case `removeBlockedApp`:
      state.child.draft.blockedApps = state.child.draft.blockedApps?.filter(
        (app) => app.id !== action.id,
      );
      return;
    case `setBlockedAppSchedule`: {
      if (!state.child.draft.blockedApps) return;
      const blockedApp = state.child.draft.blockedApps.find((k) => k.id === action.id);
      if (blockedApp) {
        blockedApp.schedule = action.schedule;
      }
      return;
    }
    case `removeKeychain`:
      state.child.draft.keychains = state.child.draft.keychains.filter(
        (keychain) => keychain.id !== action.id,
      );
      return;
    case `addKeychain`:
      state.child.draft.keychains.push(action.keychain);
      return;
    case `setDowntimeEnabled`:
      state.child.draft.downtime = action.enabled ? defaults.timeWindow() : undefined;
      return;
    case `setDowntime`:
      state.child.draft.downtime = action.downtime;
      return;
    case `setKeychainSchedule`: {
      const keychain = state.child.draft.keychains.find((k) => k.id === action.id);
      if (keychain) {
        keychain.schedule = action.schedule;
      }
      return;
    }
    case `setAddingKeychainSchedule`:
      {
        const addingKeychain = state.addingKeychain;
        if (addingKeychain) {
          addingKeychain.schedule = action.schedule;
          state.addingKeychain = addingKeychain;
        }
      }
      return;
  }
}

export default produce(reducer);
