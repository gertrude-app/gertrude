import { ConfirmDeleteEntity } from '@dash/components';
import type { StoryFn, ComponentMeta } from '@storybook/react';

export default {
  title: 'Dashboard/Modal/ConfirmDeleteEntity', // eslint-disable-line
  component: ConfirmDeleteEntity,
  parameters: { layout: `fullscreen` },
} as ComponentMeta<typeof ConfirmDeleteEntity>;

const Template: StoryFn<typeof ConfirmDeleteEntity> = (args) => (
  <ConfirmDeleteEntity {...args} />
);

export const Default = Template.bind({});
Default.args = {
  type: `widget`,
  action: {
    id: `some-id`,
    start: () => {},
    confirm: () => {},
    cancel: () => {},
  },
};
