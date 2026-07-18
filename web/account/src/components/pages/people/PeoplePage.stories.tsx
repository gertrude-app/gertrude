import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import PeoplePage from './PeoplePage';
import { people } from '#/components/storybook/fixtures';

const meta = {
  title: 'Account/Pages/People',
  component: PeoplePage,
  parameters: { layout: 'fullscreen', screenshotsAt: ['mobile', 'desktop'] },
};

export default meta;

export const Default = {
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <PeoplePage
        people={people.map((person) => ({ ...person, screenshot: null }))}
        monitorHref="/activity"
        monitorHrefForPerson={(personId) => `/activity/person/${personId}`}
      />
    </StoryScreen>
  ),
};

export const Empty = {
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <PeoplePage
        people={[]}
        monitorHref="/activity"
        monitorHrefForPerson={(personId) => `/activity/person/${personId}`}
      />
    </StoryScreen>
  ),
};
