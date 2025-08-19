import { produce } from 'immer';
import type { EditBlockRuleProps, EditEvent } from '@dash/block-rules';
import type { GetIOSDevice, WebPolicy } from '@dash/types';

export type State = {
  enabledBlockGroups: UUID[];
  webPolicyDomains: string[];
  webPolicy: WebPolicy;
  newDomain: string;
  editingBlockRule?: EditBlockRuleProps & { id?: UUID };
};

export type Action =
  | { type: `toggleBlockGroup`; id: UUID }
  | { type: `setWebPolicy`; policy: WebPolicy }
  | { type: `setNewDomain`; value: string }
  | { type: `addDomain` }
  | { type: `addBlockRule` }
  | { type: `dismissBlockRule` }
  | { type: `editBlockRule`; event: EditEvent }
  | { type: `setEditingBlockRule`; rule: EditBlockRuleProps; id: UUID }
  | { type: `removeDomain`; domain: string }
  | { type: `receiveData`; data: GetIOSDevice.Output };

function reducer(state: State, action: Action): void {
  switch (action.type) {
    case `toggleBlockGroup`: {
      const idx = state.enabledBlockGroups.indexOf(action.id);
      if (idx === -1) {
        state.enabledBlockGroups.push(action.id);
      } else {
        state.enabledBlockGroups.splice(idx, 1);
      }
      return;
    }
    case `setWebPolicy`:
      state.webPolicy = action.policy;
      return;
    case `setNewDomain`:
      state.newDomain = action.value;
      return;
    case `addDomain`: {
      const domain = state.newDomain.trim();
      if (domain && !state.webPolicyDomains.includes(domain)) {
        state.webPolicyDomains.push(domain);
        state.newDomain = ``;
      }
      return;
    }
    case `removeDomain`:
      state.webPolicyDomains = state.webPolicyDomains.filter((d) => d !== action.domain);
      return;
    case `receiveData`:
      state.enabledBlockGroups = action.data.enabledBlockGroups;
      state.webPolicy = action.data.webPolicy;
      state.webPolicyDomains = action.data.webPolicyDomains;
      return;
    case `addBlockRule`:
      state.editingBlockRule = {
        type: `app`,
        primaryValue: ``,
        secondaryValue: ``,
        condition: `always`,
      };
      return;
    case `dismissBlockRule`:
      delete state.editingBlockRule;
      return;
    case `setEditingBlockRule`:
      state.editingBlockRule = { id: action.id, ...action.rule };
      return;
    case `editBlockRule`:
      if (!state.editingBlockRule) {
        return;
      }
      switch (action.event.type) {
        case `setPrimaryValue`:
          state.editingBlockRule.primaryValue = action.event.value;
          break;
        case `setSecondaryValue`:
          state.editingBlockRule.secondaryValue = action.event.value;
          break;
        case `setType`:
          state.editingBlockRule.type = action.event.value;
          break;
        case `setCondition`:
          state.editingBlockRule.condition = action.event.value;
          break;
      }
      return;
  }
}

export default produce(reducer);
