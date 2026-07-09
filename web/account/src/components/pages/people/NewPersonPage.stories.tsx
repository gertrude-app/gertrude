import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import React from 'react';
import NewPersonPage, { type PersonRelationship } from './NewPersonPage';

const meta = {
  title: 'Account/Pages/People/New Person',
  component: NewPersonPage,
  parameters: { layout: 'fullscreen', screenshotsAt: ['mobile', 'desktop'] },
};

export default meta;

const NewPersonPageStory: React.FC = () => {
  const [relationship, setRelationship] = React.useState<PersonRelationship | null>(
    `child`,
  );
  const [name, setName] = React.useState(`Jude`);

  return (
    <NewPersonPage
      relationship={relationship}
      setRelationship={setRelationship}
      name={name}
      setName={setName}
      onFinish={() => {}}
    />
  );
};

export const Default = {
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <NewPersonPageStory />
    </StoryScreen>
  ),
};
