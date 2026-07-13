import {
  StoryCanvas,
  StorySection,
  galleryParameters,
} from '@gertrude/ui/src/storybook/StoryLayout';
import PersonCard from './PersonCard';
import { people } from '#/components/storybook/fixtures';

const meta = {
  title: 'Account/Components/People/Person Card',
  component: PersonCard,
  parameters: { layout: 'fullscreen' },
};

export default meta;

export const States = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas innerClassName="max-w-4xl">
      <StorySection
        title="With devices and recent activity"
        contentClassName="flex-col items-stretch"
      >
        <PersonCard
          person={people[0]!}
          settingsHref="/people/person-1"
          monitorHref="/activity/person/person-1"
          addDeviceHref="/people/person-1/devices/new"
        />
      </StorySection>
      <StorySection title="No devices" contentClassName="flex-col items-stretch">
        <PersonCard
          person={people[2]!}
          settingsHref="/people/person-3"
          addDeviceHref="/people/person-3/devices/new"
        />
      </StorySection>
    </StoryCanvas>
  ),
};
