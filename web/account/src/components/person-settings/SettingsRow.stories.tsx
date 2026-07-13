import {
  StoryCanvas,
  StorySection,
  galleryParameters,
} from '@gertrude/ui/src/storybook/StoryLayout';
import React from 'react';
import SettingsRow from './SettingsRow';

const meta = {
  title: 'Account/Components/Person Settings/Settings Row',
  component: SettingsRow,
  parameters: { layout: 'fullscreen', screenshotsAt: ['desktop'] },
};

export default meta;

const ToggleRow: React.FC = () => {
  const [enabled, setEnabled] = React.useState(true);

  return (
    <SettingsRow
      type="toggle"
      title="Enable Screenshots"
      description="Periodically take a screenshot and upload for your review."
      enabled={enabled}
      setEnabled={setEnabled}
    >
      <div className="rounded-xl border border-stone-200 bg-white p-3 text-sm text-stone-600">
        Additional screenshot controls
      </div>
    </SettingsRow>
  );
};

export const Types = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas innerClassName="max-w-3xl">
      <StorySection title="Rows" contentClassName="flex-col items-stretch">
        <SettingsRow
          type="alwaysOn"
          title="Always Blocked Groups"
          description="These block groups apply at all times."
        />
        <ToggleRow />
        <SettingsRow
          type="toggle"
          title="Allow Factory Reset"
          description="Allow the iPhone to be erased and reset to factory settings."
          enabled
          setEnabled={() => {}}
          warning="The user will be able to erase the iPhone, removing Gertrude and all restrictions."
          showWarning
        />
      </StorySection>
    </StoryCanvas>
  ),
};
