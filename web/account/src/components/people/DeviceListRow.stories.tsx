import { VStack } from '@gertrude/ui';
import {
  StoryCanvas,
  StorySection,
  galleryParameters,
} from '@gertrude/ui/src/storybook/StoryLayout';
import DeviceListRow from './DeviceListRow';
import { devices } from '#/components/storybook/fixtures';

const meta = {
  title: 'Account/Components/People/Device List Row',
  component: DeviceListRow,
  parameters: { layout: 'fullscreen' },
};

export default meta;

export const DeviceTypes = {
  name: 'Device types',
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas innerClassName="max-w-3xl">
      <StorySection
        title="Mac, iPhone, and iPad"
        contentClassName="flex-col items-stretch"
      >
        <VStack gap={3}>
          {devices.map((device) => (
            <DeviceListRow key={device.id} device={device} />
          ))}
        </VStack>
      </StorySection>
    </StoryCanvas>
  ),
};
