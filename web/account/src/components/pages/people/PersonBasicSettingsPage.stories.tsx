import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import React from 'react';
import type { Device } from '#/components/types';
import PersonBasicSettingsPage from './PersonBasicSettingsPage';
import PersonSettingsShellPage from './PersonSettingsShellPage';
import { devices } from '#/components/storybook/fixtures';

const meta = {
  title: 'Account/Pages/People/Person Settings',
  component: PersonBasicSettingsPage,
  parameters: { layout: 'fullscreen' },
};

export default meta;

interface BasicSettingsStoryProps {
  personDevices: Device[];
}

const BasicSettingsStory: React.FC<BasicSettingsStoryProps> = ({ personDevices }) => {
  const [personName, setPersonName] = React.useState(`Jude`);
  const [nameDraft, setNameDraft] = React.useState(personName);

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
          devices={personDevices}
          onSaveName={() => setPersonName(nameDraft.trim())}
          onDeletePerson={() => {}}
        />
      </PersonSettingsShellPage>
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

export const BasicNoDevices = {
  name: 'Basic with no devices',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => <BasicSettingsStory personDevices={[]} />,
};

export const BasicDeleteConfirmation = {
  name: 'Basic delete confirmation',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => <BasicSettingsStory personDevices={devices.slice(0, 2)} />,
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
