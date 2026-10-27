import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import React from 'react';
import type { Device, PersonRelationship } from '#/components/types';
import PersonBasicSettingsPage from './PersonBasicSettingsPage';
import PersonSettingsShellPage from './PersonSettingsShellPage';
import ConnectMacModal from '#/components/devices/ConnectMacModal';
import { devices, macDevice } from '#/components/storybook/fixtures';

const meta = {
  title: 'Account/Pages/People/Person Settings',
  component: PersonBasicSettingsPage,
  parameters: { layout: 'fullscreen' },
};

export default meta;

interface BasicSettingsStoryProps {
  personDevices: Device[];
  initialNameDraft?: string;
  initialRelationshipDraft?: PersonRelationship;
  selfRelationshipUnavailable?: boolean;
}

const BasicSettingsStory: React.FC<BasicSettingsStoryProps> = ({
  personDevices,
  initialNameDraft,
  initialRelationshipDraft,
  selfRelationshipUnavailable,
}) => {
  const [personName, setPersonName] = React.useState(`Jude`);
  const [nameDraft, setNameDraft] = React.useState(initialNameDraft ?? personName);
  const [relationship, setRelationship] = React.useState<PersonRelationship>(`child`);
  const [relationshipDraft, setRelationshipDraft] = React.useState<PersonRelationship>(
    initialRelationshipDraft ?? relationship,
  );
  const [connectMacOpen, setConnectMacOpen] = React.useState(false);
  const [connectedDevices, setConnectedDevices] = React.useState(personDevices);

  return (
    <StoryScreen>
      <PersonSettingsShellPage
        personName={personName}
        peopleHref="/people"
        baseHref="/people/person-1"
        selectedHref="/people/person-1"
      >
        <PersonBasicSettingsPage
          personName={personName}
          nameDraft={nameDraft}
          setNameDraft={setNameDraft}
          relationship={relationship}
          relationshipDraft={relationshipDraft}
          setRelationshipDraft={setRelationshipDraft}
          devices={connectedDevices}
          selfRelationshipUnavailable={selfRelationshipUnavailable}
          onSaveDetails={() => {
            setPersonName(nameDraft.trim());
            setRelationship(relationshipDraft);
          }}
          onDeletePerson={() => {}}
          onConnectMac={() => setConnectMacOpen(true)}
          onDisconnectMac={async (connectionId) => {
            setConnectedDevices((current) =>
              current.filter((device) => device.id !== connectionId),
            );
            return true;
          }}
        />
      </PersonSettingsShellPage>
      <ConnectMacModal
        open={connectMacOpen}
        onOpenChange={setConnectMacOpen}
        personName={personName}
        state={{ case: `instructions` }}
        onRequestCode={() => {}}
        onStartTrial={() => {}}
      />
    </StoryScreen>
  );
};

const waitForRender = (): Promise<void> =>
  new Promise((resolveRender) =>
    requestAnimationFrame(() => requestAnimationFrame(() => resolveRender())),
  );

export const Basic = {
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => <BasicSettingsStory personDevices={devices.slice(0, 2)} />,
};

export const BasicUnsavedChanges = {
  name: 'Basic with unsaved changes',
  parameters: {
    ...galleryParameters,
    screenshotsAt: ['mobile', 'medium', 'desktop'],
  },
  render: () => (
    <BasicSettingsStory
      personDevices={devices.slice(0, 2)}
      initialNameDraft="Jordan"
      initialRelationshipDraft="peer"
    />
  ),
};

export const BasicSelfUnavailable = {
  name: 'Basic with self relationship unavailable',
  parameters: { ...galleryParameters, screenshotsAt: ['desktop'] },
  render: () => (
    <BasicSettingsStory personDevices={devices.slice(0, 2)} selfRelationshipUnavailable />
  ),
  play: async ({ canvasElement }: { canvasElement: HTMLElement }) => {
    const relationshipSelect = Array.from(
      canvasElement.querySelectorAll<HTMLButtonElement>(`button`),
    ).find((button) => button.textContent?.trim() === `My child`);

    if (!relationshipSelect) {
      throw new Error(`Couldn't find relationship select`);
    }

    relationshipSelect.click();
    await waitForRender();

    const selfOption = Array.from(
      document.querySelectorAll<HTMLElement>(`[role="menuitem"]`),
    ).find((option) => option.textContent?.trim() === `Myself`);

    if (!selfOption) {
      throw new Error(`Couldn't find self relationship option`);
    }

    selfOption.focus();
    await new Promise((resolveTooltip) => window.setTimeout(resolveTooltip, 500));
  },
};

export const BasicNoDevices = {
  name: 'Basic with no devices',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => <BasicSettingsStory personDevices={[]} />,
};

export const BasicMultipleMacLogins = {
  name: 'Basic with multiple Mac logins',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <BasicSettingsStory
      personDevices={[
        macDevice,
        { ...macDevice, id: `mac-school`, username: `jude-school` },
        ...devices.slice(1, 2),
      ]}
    />
  ),
};

export const BasicDisconnectConfirmation = {
  name: 'Basic disconnect confirmation',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => <BasicSettingsStory personDevices={devices.slice(0, 2)} />,
  play: async ({ canvasElement }: { canvasElement: HTMLElement }) => {
    const disconnectButton = Array.from(
      canvasElement.querySelectorAll<HTMLButtonElement>(`button`),
    ).find((button) => button.textContent?.trim() === `Disconnect`);

    if (!disconnectButton) {
      throw new Error(`Couldn't find Mac disconnect button`);
    }

    disconnectButton.click();
    await waitForRender();
  },
};

export const BasicDeleteConfirmation = {
  name: 'Basic delete confirmation',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <div className="h-svh overflow-hidden">
      <BasicSettingsStory personDevices={devices.slice(0, 2)} />
    </div>
  ),
  play: async ({ canvasElement }: { canvasElement: HTMLElement }) => {
    const deleteButton = Array.from(
      canvasElement.querySelectorAll<HTMLButtonElement>(`button`),
    ).find((button) => button.textContent?.trim() === `Delete Jude`);

    if (!deleteButton) {
      throw new Error(`Couldn't find person delete button`);
    }

    deleteButton.click();
    await waitForRender();
  },
};
