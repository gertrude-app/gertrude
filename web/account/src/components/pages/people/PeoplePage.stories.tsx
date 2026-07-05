import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import PeoplePage from './PeoplePage';
import {
  people,
  securityEvents,
  suspensionRequests,
  unlockRequests,
} from '#/components/storybook/fixtures';

const meta = {
  title: 'Account/Pages/People/List',
  component: PeoplePage,
  parameters: { layout: 'fullscreen' },
};

export default meta;

export const Default = {
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <PeoplePage
        people={people}
        securityEvents={securityEvents}
        suspensionRequests={suspensionRequests}
        unlockRequests={unlockRequests}
        addPersonHref="/people/new"
        monitorHref="/activity"
        settingsHrefForPerson={(personId) => `/people/${personId}`}
        monitorHrefForPerson={(personId) => `/activity/person/${personId}`}
        addDeviceHrefForPerson={(personId) => `/people/${personId}/devices/new`}
        suspensionRequestsHref="/requests/suspension"
        unlockRequestsHref="/requests/unlock"
        securityEventsHref="/security-events"
      />
    </StoryScreen>
  ),
};
