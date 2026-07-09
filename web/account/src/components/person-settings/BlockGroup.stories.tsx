import {
  StoryCanvas,
  StorySection,
  galleryParameters,
} from '@gertrude/ui/src/storybook/StoryLayout';
import React from 'react';
import BlockGroup from './BlockGroup';

const meta = {
  title: 'Account/Components/Person Settings/Block Group',
  component: BlockGroup,
  parameters: { layout: 'fullscreen', screenshotsAt: ['desktop'] },
};

export default meta;

const BlockGroupStory: React.FC = () => {
  const [adultContentBlocked, setAdultContentBlocked] = React.useState(true);
  const [socialMediaBlocked, setSocialMediaBlocked] = React.useState(false);

  return (
    <div className="bg-white border border-stone-200 rounded-xl shadow shadow-stone-300/30 flex flex-col overflow-hidden">
      <BlockGroup
        title="Adult Content"
        shortDescription="Block the most-trafficked adult websites, plus adult-oriented TLDs."
        longExplanation="Blocks roughly 50 of the most-trafficked adult sites by current web traffic, plus the adult-oriented top-level domains."
        blocked={adultContentBlocked}
        setBlocked={setAdultContentBlocked}
      />
      <BlockGroup
        title="Social Media"
        shortDescription="Block the most prominent social media sites."
        longExplanation="Blocks Instagram, TikTok, X, Facebook, Snapchat, Threads, and Pinterest."
        blocked={socialMediaBlocked}
        setBlocked={setSocialMediaBlocked}
        defaultExpanded
      />
    </div>
  );
};

export const States = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas innerClassName="max-w-3xl">
      <StorySection
        title="Blocked and unblocked"
        contentClassName="flex-col items-stretch"
      >
        <BlockGroupStory />
      </StorySection>
    </StoryCanvas>
  ),
};
