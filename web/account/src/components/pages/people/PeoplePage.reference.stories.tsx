import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import PeoplePageReference from './PeoplePage.reference';
import {
  people,
  securityEvents,
  suspensionRequests,
  unlockRequests,
} from '#/components/storybook/fixtures';

const noop = (): void => {};

const meta = {
  title: 'Account/Design References/People',
  component: PeoplePageReference,
  parameters: { layout: 'fullscreen', screenshotsAt: ['mobile', 'desktop'] },
};

export default meta;

export const Default = {
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <PeoplePageReference
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
        suspensionRequestHrefForRequest={(id) => `/requests/suspension/${id}`}
        onRefreshSuspensionRequests={noop}
        onRefreshSecurityEvents={noop}
        unlockRequestsHref="/requests/unlock"
        securityEventsHref="/security-events"
      />
    </StoryScreen>
  ),
};
