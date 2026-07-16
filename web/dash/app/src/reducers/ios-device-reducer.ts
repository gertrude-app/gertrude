import { produce } from 'immer';
import type { ExtControlsState } from '../lib/extendedRestrictions';
import type { EditBlockRuleProps, EditEvent } from '@dash/block-rules';
import type { AllowListBookmark, GetIOSDevice_v2, WebPolicy } from '@dash/types';
import { normalizeExtended } from '../lib/extendedRestrictions';

export type State = {
  enabledBlockGroups: UUID[];
  webPolicyDomains: string[];
  webPolicy: WebPolicy;
  newDomain: string;
  isProfileLocked: boolean;
  allowAppRemoval: boolean;
  allowEraseContentAndSettings: boolean;
  allowAppInstallation: boolean;
  hasExtendedControls: boolean;
  whitelistedAppBundleIds: string[] | null;
  newBundleId: string;
  webAllowList: AllowListBookmark[] | null;
  newBookmarkUrl: string;
  newBookmarkTitle: string;
  extended: ExtControlsState;
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
  | { type: `setAppWhitelistEnabled`; value: boolean }
  | { type: `setNewBundleId`; value: string }
  | { type: `addBundleId` }
  | { type: `removeBundleId`; bundleId: string }
  | { type: `setWebAllowListEnabled`; value: boolean }
  | { type: `setNewBookmarkUrl`; value: string }
  | { type: `setNewBookmarkTitle`; value: string }
  | { type: `addBookmark` }
  | { type: `removeBookmark`; url: string }
  | { type: `setIsProfileLocked`; value: boolean }
  | { type: `setAllowAppRemoval`; value: boolean }
  | { type: `setAllowEraseContentAndSettings`; value: boolean }
  | { type: `setAllowAppInstallation`; value: boolean }
  | { type: `setExtendedControls`; values: Partial<ExtControlsState> }
  | { type: `receiveData`; data: GetIOSDevice_v2.Output };

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
    case `setAppWhitelistEnabled`:
      state.whitelistedAppBundleIds = action.value
        ? (state.whitelistedAppBundleIds ?? [])
        : null;
      return;
    case `setNewBundleId`:
      state.newBundleId = action.value;
      return;
    case `addBundleId`: {
      const bundleId = state.newBundleId.trim();
      if (
        bundleId &&
        state.whitelistedAppBundleIds &&
        !state.whitelistedAppBundleIds.includes(bundleId)
      ) {
        state.whitelistedAppBundleIds.push(bundleId);
        state.newBundleId = ``;
      }
      return;
    }
    case `removeBundleId`:
      if (state.whitelistedAppBundleIds) {
        state.whitelistedAppBundleIds = state.whitelistedAppBundleIds.filter(
          (id) => id !== action.bundleId,
        );
      }
      return;
    case `setWebAllowListEnabled`:
      state.webAllowList = action.value ? (state.webAllowList ?? []) : null;
      return;
    case `setNewBookmarkUrl`:
      state.newBookmarkUrl = action.value;
      return;
    case `setNewBookmarkTitle`:
      state.newBookmarkTitle = action.value;
      return;
    case `addBookmark`: {
      const url = state.newBookmarkUrl.trim();
      const title = state.newBookmarkTitle.trim();
      if (
        url &&
        title &&
        state.webAllowList &&
        !state.webAllowList.some((b) => b.url === url)
      ) {
        state.webAllowList.push({ url, title });
        state.newBookmarkUrl = ``;
        state.newBookmarkTitle = ``;
      }
      return;
    }
    case `removeBookmark`:
      if (state.webAllowList) {
        state.webAllowList = state.webAllowList.filter((b) => b.url !== action.url);
      }
      return;
    case `setIsProfileLocked`:
      state.isProfileLocked = action.value;
      return;
    case `setAllowAppRemoval`:
      state.allowAppRemoval = action.value;
      return;
    case `setAllowEraseContentAndSettings`:
      state.allowEraseContentAndSettings = action.value;
      return;
    case `setAllowAppInstallation`:
      state.allowAppInstallation = action.value;
      return;
    case `setExtendedControls`:
      Object.assign(state.extended, action.values);
      return;
    case `receiveData`: {
      const blocker = action.data.blocker;
      if (!blocker) return;
      state.enabledBlockGroups = [...blocker.enabledBlockGroups];
      state.webPolicy = blocker.webPolicy;
      state.webPolicyDomains = [...blocker.webPolicyDomains];
      state.isProfileLocked = blocker.isProfileLocked;
      state.allowAppRemoval = blocker.allowAppRemoval;
      state.allowEraseContentAndSettings = blocker.allowEraseContentAndSettings;
      state.allowAppInstallation = blocker.allowAppInstallation;
      const extended = blocker.extendedSupervisionControls;
      state.hasExtendedControls = extended !== undefined;
      state.whitelistedAppBundleIds = extended?.whitelistedAppBundleIds
        ? [...extended.whitelistedAppBundleIds]
        : null;
      state.webAllowList = extended?.webAllowList
        ? extended.webAllowList.map((b) => ({ ...b }))
        : null;
      state.extended = normalizeExtended(extended);
      return;
    }
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
