import { extendedControlsPayload, normalizeExtended } from '@shared/pairql/supervision';
import type { IosBlockerSettings, IosProfileSettings } from './IosSettingsPage.types';
import type {
  AllowListBookmark,
  ExtendedSupervisionControls,
} from '@shared/pairql/src/account';
import type { ExtControlsState } from '@shared/pairql/supervision';

export interface BlockedGroupsDraft {
  enabledIds: string[];
}

export type ProfileDraft = IosProfileSettings;

export interface ExtendedControlsDraft extends ExtControlsState {
  whitelistedAppBundleIds: string[] | null;
  webAllowList: AllowListBookmark[] | null;
}

interface EditableForm<Draft> {
  saved: Draft;
  draft: Draft;
}

export type BlockedGroupsFormState = EditableForm<BlockedGroupsDraft>;
export type ProfileFormState = EditableForm<ProfileDraft>;
export type ExtendedControlsFormState = EditableForm<ExtendedControlsDraft>;

export interface IosSettingsFormState {
  blockedGroups: BlockedGroupsFormState;
  profile: ProfileFormState;
  extended?: ExtendedControlsFormState;
}

export type IosSettingsAction =
  | { type: `settingsReceived`; blocker: IosBlockerSettings }
  | { type: `blockGroupChanged`; id: string; blocked: boolean }
  | { type: `blockedGroupsSaveSucceeded`; submitted: BlockedGroupsDraft }
  | { type: `profileFlagChanged`; flag: keyof ProfileDraft; enabled: boolean }
  | { type: `profileSaveSucceeded`; submitted: ProfileDraft }
  | { type: `extendedControlsChanged`; values: Partial<ExtendedControlsDraft> }
  | { type: `extendedControlsSaveSucceeded`; submitted: ExtendedControlsDraft };

const blockedGroupsDraft = (blocker: IosBlockerSettings): BlockedGroupsDraft => ({
  enabledIds: blocker.enabledBlockGroupIds,
});

const profileDraft = (blocker: IosBlockerSettings): ProfileDraft => ({
  ...blocker.profileSettings,
});

const editableForm = <Draft>(draft: Draft): EditableForm<Draft> => ({
  saved: draft,
  draft,
});

export const createIosSettingsFormState = (
  blocker: IosBlockerSettings,
): IosSettingsFormState => ({
  blockedGroups: editableForm(blockedGroupsDraft(blocker)),
  profile: editableForm(profileDraft(blocker)),
  extended: blocker.extendedSupervisionControls
    ? editableForm({
        ...normalizeExtended(blocker.extendedSupervisionControls),
        whitelistedAppBundleIds:
          blocker.extendedSupervisionControls.whitelistedAppBundleIds ?? null,
        webAllowList: blocker.extendedSupervisionControls.webAllowList ?? null,
      })
    : undefined,
});

// enabled ids are an unordered set; the server returns them in catalog order
const sortedIds = ({ enabledIds }: BlockedGroupsDraft): string =>
  JSON.stringify([...enabledIds].sort());

export const blockedGroupsHaveUnsavedChanges = ({
  saved,
  draft,
}: BlockedGroupsFormState): boolean => sortedIds(draft) !== sortedIds(saved);

export const profileHasUnsavedChanges = ({ saved, draft }: ProfileFormState): boolean =>
  draft.preventProtectionRemoval !== saved.preventProtectionRemoval ||
  draft.allowDeletingApps !== saved.allowDeletingApps ||
  draft.allowFactoryReset !== saved.allowFactoryReset ||
  draft.allowInstallingApps !== saved.allowInstallingApps;

export const extendedControlsInput = (
  draft: ExtendedControlsDraft,
): ExtendedSupervisionControls => ({
  ...extendedControlsPayload(draft),
  whitelistedAppBundleIds: draft.whitelistedAppBundleIds ?? undefined,
  webAllowList: draft.webAllowList?.map(({ url, title }) => ({ url, title })),
});

export const extendedControlsHaveUnsavedChanges = (
  state: ExtendedControlsFormState | undefined,
): boolean =>
  !!state &&
  JSON.stringify(extendedControlsInput(state.draft)) !==
    JSON.stringify(extendedControlsInput(state.saved));

const iosSettingsReducer = (
  state: IosSettingsFormState,
  action: IosSettingsAction,
): IosSettingsFormState => {
  switch (action.type) {
    case `settingsReceived`: {
      const received = createIosSettingsFormState(action.blocker);
      return {
        blockedGroups: blockedGroupsHaveUnsavedChanges(state.blockedGroups)
          ? state.blockedGroups
          : received.blockedGroups,
        profile: profileHasUnsavedChanges(state.profile)
          ? state.profile
          : received.profile,
        extended:
          received.extended && extendedControlsHaveUnsavedChanges(state.extended)
            ? state.extended
            : received.extended,
      };
    }
    case `blockGroupChanged`: {
      const { enabledIds } = state.blockedGroups.draft;
      return {
        ...state,
        blockedGroups: {
          ...state.blockedGroups,
          draft: {
            enabledIds: action.blocked
              ? enabledIds.includes(action.id)
                ? enabledIds
                : [...enabledIds, action.id]
              : enabledIds.filter((id) => id !== action.id),
          },
        },
      };
    }
    case `blockedGroupsSaveSucceeded`:
      return {
        ...state,
        blockedGroups: {
          saved: action.submitted,
          draft: state.blockedGroups.draft,
        },
      };
    case `profileFlagChanged`:
      return {
        ...state,
        profile: {
          ...state.profile,
          draft: { ...state.profile.draft, [action.flag]: action.enabled },
        },
      };
    case `extendedControlsChanged`:
      return state.extended
        ? {
            ...state,
            extended: {
              ...state.extended,
              draft: { ...state.extended.draft, ...action.values },
            },
          }
        : state;
    case `extendedControlsSaveSucceeded`:
      return state.extended
        ? {
            ...state,
            extended: { saved: action.submitted, draft: state.extended.draft },
          }
        : state;
    case `profileSaveSucceeded`:
      return {
        ...state,
        profile: {
          saved: action.submitted,
          draft: state.profile.draft,
        },
      };
  }
};

export default iosSettingsReducer;
