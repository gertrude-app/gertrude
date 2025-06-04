import { EditComputer } from '@dash/components';
import type { Meta, StoryObj } from '@storybook/react';
import { withStatefulChrome } from '../../decorators/StatefulChrome';
import { props } from '../../story-helpers';

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
      status: { case: `offline` },
    },
    {
      name: `Little Jimmy`,
      id: `123`,
      status: { case: `filterOn` },
    },
  ],
  saveButtonDisabled: false,
  onSave: () => {},
});

export default meta;
