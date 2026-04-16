import { defaults } from '@dash/types';
import { produce } from 'immer';
import { v4 as uuid } from 'uuid';
import type { EditBlockRuleProps, EditEvent } from '@dash/block-rules';
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
  editingAlwaysBlockedRule?: EditBlockRuleProps & { id?: UUID };
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
  | { type: `setAddingKeychain`; keychain?: UserKeychainSummary | null }
  | { type: `toggleAlwaysBlockedGroup`; id: UUID }
  | { type: `addAlwaysBlockedRule` }
  | { type: `editAlwaysBlockedRule`; id: UUID; rule: EditBlockRuleProps }
  | { type: `editAlwaysBlockedRuleForm`; event: EditEvent }
  | { type: `saveAlwaysBlockedRule` }
  | { type: `dismissAlwaysBlockedRule` }
  | { type: `deleteAlwaysBlockedRule`; id: UUID };

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
    case `toggleAlwaysBlockedGroup`: {
      const current = state.child.draft.alwaysBlockedGroupIds;
      const idx = current.indexOf(action.id);
      if (idx === -1) {
        current.push(action.id);
      } else {
        current.splice(idx, 1);
      }
      return;
    }
    case `addAlwaysBlockedRule`:
      state.editingAlwaysBlockedRule = {
        type: `address`,
        primaryValue: ``,
        secondaryValue: ``,
        condition: `always`,
      };
      return;
    case `editAlwaysBlockedRule`:
      state.editingAlwaysBlockedRule = { id: action.id, ...action.rule };
      return;
    case `dismissAlwaysBlockedRule`:
      delete state.editingAlwaysBlockedRule;
      return;
    case `editAlwaysBlockedRuleForm`:
      if (!state.editingAlwaysBlockedRule) return;
      switch (action.event.type) {
        case `setPrimaryValue`:
          state.editingAlwaysBlockedRule.primaryValue = action.event.value;
          break;
        case `setSecondaryValue`:
          state.editingAlwaysBlockedRule.secondaryValue = action.event.value;
          break;
        case `setType`:
          state.editingAlwaysBlockedRule.type = action.event.value;
          break;
        case `setCondition`:
          state.editingAlwaysBlockedRule.condition = action.event.value;
          break;
      }
      return;
    case `saveAlwaysBlockedRule`: {
      const editing = state.editingAlwaysBlockedRule;
      if (!editing) return;
      const value = editing.primaryValue.trim();
      if (!value) return;
      const rule = { case: `hostnameOrSubdomain`, value } as const;
      const rules = state.child.draft.customAlwaysBlockedRules;
      if (editing.id) {
        const existing = rules.find((r) => r.id === editing.id);
        if (existing) {
          existing.rule = rule;
        }
      } else {
        rules.push({ id: uuid(), rule, comment: undefined });
      }
      delete state.editingAlwaysBlockedRule;
      return;
    }
    case `deleteAlwaysBlockedRule`:
      state.child.draft.customAlwaysBlockedRules =
        state.child.draft.customAlwaysBlockedRules.filter((r) => r.id !== action.id);
      return;
  }
}

export default produce(reducer);
