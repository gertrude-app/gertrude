import { Banner, Button, Card, EmptyState, HStack, Skeleton, VStack } from '@gertrude/ui';
import {
  CircleAlertIcon,
  MusicIcon,
  PodcastIcon,
  RefreshCwIcon,
  SmartphoneIcon,
} from 'lucide-react';
import React from 'react';
import type { PersonSettingsPreviewChip } from '#/components/person-settings/PersonSettingsExpandableSection';
import type { LoadableState } from '#/components/types';
import type {
  BlockedGroupsFormState,
  IosSettingsAction,
  ProfileDraft,
  ProfileFormState,
} from './IosSettingsPage.reducer';
import type {
  IosBlockerSettings,
  IosDeviceSettingsConfiguration,
} from './IosSettingsPage.types';
import iosSettingsReducer, {
  blockedGroupsHaveUnsavedChanges,
  createIosSettingsFormState,
  profileHasUnsavedChanges,
} from './IosSettingsPage.reducer';
import CardContainer from '#/components/layout/CardContainer';
import AppNotInstalledSection from '#/components/person-settings/AppNotInstalledSection';
import BlockGroup from '#/components/person-settings/BlockGroup';
import MusicSection from '#/components/person-settings/MusicSection';
import PersonSettingsExpandableSection from '#/components/person-settings/PersonSettingsExpandableSection';
import PodcastsSection from '#/components/person-settings/PodcastsSection';
import SettingsRow from '#/components/person-settings/SettingsRow';

interface Props {
  state: LoadableState<IosDeviceSettingsConfiguration>;
  savingBlockedGroups?: boolean;
  savingProfile?: boolean;
  requestingPinReset?: boolean;
  onSaveBlockedGroups: (enabledBlockGroupIds: string[]) => void | Promise<void>;
  onSaveProfile: (profileSettings: ProfileDraft) => void | Promise<void>;
  onRequestPodcastsPinReset?: () => Promise<number | null>;
  onUnsavedChangesChange?: (hasUnsavedChanges: boolean) => void;
}

const SaveButton: React.FC<{ disabled: boolean; saving: boolean }> = ({
  disabled,
  saving,
}) => (
  <HStack justify="end">
    <Button
      type="submit"
      variant="primary"
      disabled={disabled}
      loading={saving}
      className="w-full @lg/main:w-auto"
    >
      Save Changes
    </Button>
  </HStack>
);

const SubsectionDivider: React.FC<{ title: string }> = ({ title }) => (
  <div className="flex items-center gap-3 mt-8 mb-4">
    <div className="h-[1.5px] flex-grow bg-stone-200 rounded-full" />
    <span className="font-medium text-stone-900">{title}</span>
    <div className="h-[1.5px] flex-grow bg-stone-200 rounded-full" />
  </div>
);

interface BlockedGroupsFormProps {
  blocker: IosBlockerSettings;
  state: BlockedGroupsFormState;
  dispatch: React.Dispatch<IosSettingsAction>;
  saving: boolean;
  onSave: (enabledBlockGroupIds: string[]) => void | Promise<void>;
}

const BlockedGroupsForm: React.FC<BlockedGroupsFormProps> = ({
  blocker,
  state,
  dispatch,
  saving,
  onSave,
}) => {
  const { draft } = state;
  const hasUnsavedChanges = blockedGroupsHaveUnsavedChanges(state);

  const save = (): void => {
    if (!hasUnsavedChanges || saving) {
      return;
    }
    const submitted = { enabledIds: draft.enabledIds };
    void Promise.resolve(onSave(submitted.enabledIds)).then(
      () => dispatch({ type: `blockedGroupsSaveSucceeded`, submitted }),
      () => undefined,
    );
  };

  return (
    <form
      onSubmit={(event) => {
        event.preventDefault();
        save();
      }}
    >
      <VStack gap={3}>
        <SettingsRow
          type="alwaysOn"
          title="Blocked Groups"
          description="These content categories are blocked on this device."
        >
          <Card padding={0} className="overflow-hidden">
            {blocker.allBlockGroups.map((group) => (
              <BlockGroup
                key={group.id}
                title={group.name}
                shortDescription={group.description}
                longExplanation={group.longDescription}
                blocked={draft.enabledIds.includes(group.id)}
                setBlocked={(blocked) =>
                  dispatch({ type: `blockGroupChanged`, id: group.id, blocked })
                }
              />
            ))}
          </Card>
        </SettingsRow>
        <SaveButton disabled={!hasUnsavedChanges || saving} saving={saving} />
      </VStack>
    </form>
  );
};

interface ProfileFormProps {
  state: ProfileFormState;
  dispatch: React.Dispatch<IosSettingsAction>;
  saving: boolean;
  onSave: (profileSettings: ProfileDraft) => void | Promise<void>;
}

const ProfileForm: React.FC<ProfileFormProps> = ({ state, dispatch, saving, onSave }) => {
  const { draft } = state;
  const hasUnsavedChanges = profileHasUnsavedChanges(state);

  const save = (): void => {
    if (!hasUnsavedChanges || saving) {
      return;
    }
    const submitted = { ...draft };
    void Promise.resolve(onSave(submitted)).then(
      () => dispatch({ type: `profileSaveSucceeded`, submitted }),
      () => undefined,
    );
  };

  return (
    <form
      onSubmit={(event) => {
        event.preventDefault();
        save();
      }}
    >
      <Banner variant="warning">
        After changing any setting below, you’ll need to sync the profile on the device by
        opening the Gertrude app and going to <strong>Info → Sync Profile</strong>.
      </Banner>
      <VStack gap={3} className="mt-3">
        <SettingsRow
          title="Prevent Protection Removal"
          description="Make it impossible for the device user to remove Gertrude’s protection."
          type="toggle"
          enabled={draft.preventProtectionRemoval}
          setEnabled={(enabled) =>
            dispatch({
              type: `profileFlagChanged`,
              flag: `preventProtectionRemoval`,
              enabled,
            })
          }
          warning="The device user may remove the profile in order to stop Gertrude’s protection and uninstall."
          showWarning={!draft.preventProtectionRemoval}
        />
        <SettingsRow
          title="Allow Deleting Apps"
          description="Keeping this off prevents the device user from deleting the Gertrude app, but also prevents them from deleting any app. Enable temporarily if you need to delete some apps, then re-enable."
          type="toggle"
          enabled={draft.allowDeletingApps}
          setEnabled={(enabled) =>
            dispatch({ type: `profileFlagChanged`, flag: `allowDeletingApps`, enabled })
          }
          warning="The user can delete apps (including Gertrude Blocker) from their device."
          showWarning={draft.allowDeletingApps}
        />
        <SettingsRow
          title="Allow Factory Reset"
          description="Allow the device to be erased and reset to factory settings, bypassing protection."
          type="toggle"
          enabled={draft.allowFactoryReset}
          setEnabled={(enabled) =>
            dispatch({ type: `profileFlagChanged`, flag: `allowFactoryReset`, enabled })
          }
          warning="The user will be able to erase the device, removing Gertrude and all restrictions."
          showWarning={draft.allowFactoryReset}
        />
        <SettingsRow
          title="Allow Installing Apps"
          description="Allow the device user to install new apps from the App Store. Turn this off to remove the App Store icon entirely and block app installation."
          type="toggle"
          enabled={draft.allowInstallingApps}
          setEnabled={(enabled) =>
            dispatch({ type: `profileFlagChanged`, flag: `allowInstallingApps`, enabled })
          }
        />
        <SaveButton disabled={!hasUnsavedChanges || saving} saving={saving} />
      </VStack>
    </form>
  );
};

interface EditorProps {
  blocker: IosBlockerSettings;
  savingBlockedGroups: boolean;
  savingProfile: boolean;
  onSaveBlockedGroups: (enabledBlockGroupIds: string[]) => void | Promise<void>;
  onSaveProfile: (profileSettings: ProfileDraft) => void | Promise<void>;
  onUnsavedChangesChange?: (hasUnsavedChanges: boolean) => void;
}

const IosSettingsEditor: React.FC<EditorProps> = ({
  blocker,
  savingBlockedGroups,
  savingProfile,
  onSaveBlockedGroups,
  onSaveProfile,
  onUnsavedChangesChange,
}) => {
  const [formState, dispatch] = React.useReducer(
    iosSettingsReducer,
    blocker,
    createIosSettingsFormState,
  );
  const blockedGroupsHaveChanges = blockedGroupsHaveUnsavedChanges(
    formState.blockedGroups,
  );
  const profileHasChanges = profileHasUnsavedChanges(formState.profile);
  const hasUnsavedChanges =
    blockedGroupsHaveChanges || (blocker.isSupervised && profileHasChanges);

  React.useEffect(() => {
    dispatch({ type: `settingsReceived`, blocker });
  }, [blocker, blockedGroupsHaveChanges, profileHasChanges]);

  React.useEffect(() => {
    onUnsavedChangesChange?.(hasUnsavedChanges);
  }, [hasUnsavedChanges, onUnsavedChangesChange]);

  React.useEffect(
    () => () => {
      onUnsavedChangesChange?.(false);
    },
    [onUnsavedChangesChange],
  );

  const blockedCount = formState.blockedGroups.draft.enabledIds.length;
  const { draft: profile } = formState.profile;
  const protections = [
    profile.preventProtectionRemoval,
    !profile.allowDeletingApps,
    !profile.allowFactoryReset,
  ].filter(Boolean).length;
  const previewChips: PersonSettingsPreviewChip[] = [
    {
      title: `Blocked Groups`,
      values: [
        {
          text: `${blockedCount} of ${blocker.allBlockGroups.length}`,
          color: blockedCount > 0 ? `violet` : `neutral`,
        },
      ],
    },
    blocker.isSupervised
      ? {
          title: `Protections`,
          values: [
            {
              text: `${protections} of 3`,
              color: protections === 3 ? `violet` : `neutral`,
            },
          ],
        }
      : null,
  ];

  return (
    <>
      {(savingBlockedGroups || savingProfile) && (
        <span role="status" className="sr-only">
          Saving Gertrude Blocker settings
        </span>
      )}
      <PersonSettingsExpandableSection
        appIconUrl="/gertrude-app-icons/blocker.webp"
        title="Gertrude Blocker"
        hasUnsavedChanges={hasUnsavedChanges}
        previewChips={previewChips}
      >
        <BlockedGroupsForm
          blocker={blocker}
          state={formState.blockedGroups}
          dispatch={dispatch}
          saving={savingBlockedGroups}
          onSave={onSaveBlockedGroups}
        />
        {blocker.isSupervised && (
          <>
            <SubsectionDivider title="Supervision Profile Settings" />
            <ProfileForm
              state={formState.profile}
              dispatch={dispatch}
              saving={savingProfile}
              onSave={onSaveProfile}
            />
          </>
        )}
      </PersonSettingsExpandableSection>
    </>
  );
};

const IosSettingsPage: React.FC<Props> = ({
  state,
  savingBlockedGroups = false,
  savingProfile = false,
  requestingPinReset = false,
  onSaveBlockedGroups,
  onSaveProfile,
  onRequestPodcastsPinReset,
  onUnsavedChangesChange,
}) => {
  if (state.status === `loading`) {
    return (
      <CardContainer className="flex flex-col gap-4">
        <span role="status" className="sr-only">
          Loading iPhone/iPad settings
        </span>
        <Skeleton className="h-14 w-full" radius="large" />
        <Skeleton className="h-28 w-full" radius="large" />
      </CardContainer>
    );
  }

  if (state.status === `error`) {
    return (
      <CardContainer>
        <div role="alert">
          <EmptyState
            icon={CircleAlertIcon}
            title="Couldn't load iPhone/iPad settings"
            description={state.message}
            button={{
              text: `Try again`,
              type: `button`,
              onClick: state.onRetry,
              icon: RefreshCwIcon,
            }}
            className="bg-white"
          />
        </div>
      </CardContainer>
    );
  }

  const { blocker, podcasts, music, deviceName } = state.data;

  return (
    <CardContainer className="flex flex-col gap-4">
      {blocker ? (
        <IosSettingsEditor
          blocker={blocker}
          savingBlockedGroups={savingBlockedGroups}
          savingProfile={savingProfile}
          onSaveBlockedGroups={onSaveBlockedGroups}
          onSaveProfile={onSaveProfile}
          onUnsavedChangesChange={onUnsavedChangesChange}
        />
      ) : (
        <PersonSettingsExpandableSection
          appIconUrl="/gertrude-app-icons/blocker.webp"
          title="Gertrude Blocker"
          previewChips={[
            {
              title: `Status`,
              values: [{ text: `Not connected`, color: `neutral` }],
            },
          ]}
        >
          <EmptyState
            icon={SmartphoneIcon}
            title="Gertrude Blocker isn’t connected"
            description={`${deviceName} is linked to this account, but the Gertrude Blocker app hasn’t been connected on it, so there are no settings to manage yet.`}
            className="bg-white"
          />
        </PersonSettingsExpandableSection>
      )}
      {music ? (
        <MusicSection music={music} />
      ) : (
        <AppNotInstalledSection
          appIconUrl="/gertrude-app-icons/music.webp"
          appName="Gertrude Music"
          icon={MusicIcon}
          description="Gertrude Music is a music app that only plays albums you’ve approved, with no artwork, no radio, and nothing to stumble into."
          appStoreUrl="https://apps.apple.com/us/app/gertrude-music/id6782194077"
        />
      )}
      {podcasts && onRequestPodcastsPinReset ? (
        <PodcastsSection
          subscription={podcasts.subscription}
          deviceName={deviceName}
          requestingPinReset={requestingPinReset}
          onRequestPinReset={onRequestPodcastsPinReset}
        />
      ) : (
        <AppNotInstalledSection
          appIconUrl="/gertrude-app-icons/podcasts.webp"
          appName="Gertrude Podcasts"
          icon={PodcastIcon}
          description="Gertrude Podcasts plays only the shows you’ve approved, with a PIN you control so the lineup can’t be changed."
          appStoreUrl="https://apps.apple.com/us/app/gertrude-podcasts/id6753187429"
        />
      )}
    </CardContainer>
  );
};

export default IosSettingsPage;
