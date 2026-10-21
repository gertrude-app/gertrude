import {
  StoryCanvas,
  StorySection,
  galleryParameters,
} from '@gertrude/ui/src/storybook/StoryLayout';
import type { Announcement } from '#/components/types';
import AnnouncementBanner from './AnnouncementBanner';

const news: Announcement = {
  id: `news`,
  kind: `news`,
  html: `Meet <b>Gertrude Podcasts</b>: a simpler way for kids to enjoy only the shows you approve. Searching and adding shows stays protected behind your PIN.`,
  action: {
    label: `Meet Gertrude Podcasts`,
    url: `https://gertrude.app/updates/gertrude-podcasts-launch`,
  },
};

const warning: Announcement = {
  id: `warning`,
  kind: `warning`,
  html: `<b>Action needed:</b> Screen Time web filtering is enabled on <b>Jude’s Mac</b>, which can interfere with Gertrude’s protection. Disable Screen Time’s “Content &amp; Privacy” restrictions to fix the conflict.`,
  action: {
    label: `How to fix this`,
    url: `https://gertrude.app/help/mac/screen-time-filter-conflict`,
  },
};

const noop = (): void => {};

const meta = {
  title: 'Account/Components/Announcement Banner',
  component: AnnouncementBanner,
  parameters: { layout: 'fullscreen' },
};

export default meta;

export const Assortment = {
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <StoryCanvas>
      <StorySection title="News" contentClassName="block">
        <AnnouncementBanner announcement={news} onDismiss={noop} />
      </StorySection>
      <StorySection title="Warning" contentClassName="block">
        <AnnouncementBanner announcement={warning} onDismiss={noop} />
      </StorySection>
      <StorySection title="Without an action" contentClassName="block">
        <AnnouncementBanner
          announcement={{ ...news, action: undefined }}
          onDismiss={noop}
        />
      </StorySection>
      <StorySection title="Dismissing" contentClassName="block">
        <AnnouncementBanner announcement={news} onDismiss={noop} dismissing />
      </StorySection>
      <StorySection title="Dismissal failed" contentClassName="block">
        <AnnouncementBanner
          announcement={warning}
          onDismiss={noop}
          error="Couldn't dismiss this announcement. Please try again."
        />
      </StorySection>
    </StoryCanvas>
  ),
};
