import { EditComputer } from '@dash/components';
import type { StoryObj, Meta } from '@storybook/react';
import { props } from '../../story-helpers';
import { withStatefulChrome } from '../../decorators/StatefulChrome';

const meta = {
  title: 'Dashboard/Computers/EditComputer', // eslint-disable-line
  component: EditComputer,
  parameters: { layout: `fullscreen` },
  decorators: [withStatefulChrome],
} satisfies Meta<typeof EditComputer>;

type Story = StoryObj<typeof meta>;

// @screenshot: xs,md
export const Default: Story = props({
  name: `Silvery`,
  setName: () => {},
  releaseChannel: `stable`,
  setReleaseChannel: () => {},
  modelTitle: `16" MacBook Pro (2023)`,
  serialNumber: `C02XV0Y1JGH7`,
  modelIdentifier: `Mac14,10`,
  appVersion: `2.2.1`,
  latestReleaseVersion: `2.2.1`,
  users: [
    {
      name: `Sally`,
      id: `456`,
      isOnline: false,
    },
    {
      name: `Little Jimmy`,
      id: `123`,
      isOnline: true,
    },
  ],
  saveButtonDisabled: false,
  onSave: () => {},
});

export default meta;
