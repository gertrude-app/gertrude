import type { IosBlockerSettings, IosProfileSettings } from './IosSettingsPage.types';

export interface BlockedGroupsDraft {
  enabledIds: string[];
}

export type ProfileDraft = IosProfileSettings;

interface EditableForm<Draft> {
  saved: Draft;
  draft: Draft;
}

export type BlockedGroupsFormState = EditableForm<BlockedGroupsDraft>;
export type ProfileFormState = EditableForm<ProfileDraft>;

export interface IosSettingsFormState {
  blockedGroups: BlockedGroupsFormState;
  profile: ProfileFormState;
}

export type IosSettingsAction =
  | { type: `settingsReceived`; blocker: IosBlockerSettings }
  | { type: `blockGroupChanged`; id: string; blocked: boolean }
  | { type: `blockedGroupsSaveSucceeded`; submitted: BlockedGroupsDraft }
  | { type: `profileFlagChanged`; flag: keyof ProfileDraft; enabled: boolean }
  | { type: `profileSaveSucceeded`; submitted: ProfileDraft };

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
