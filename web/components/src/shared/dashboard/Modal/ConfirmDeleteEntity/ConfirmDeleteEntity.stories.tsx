import { ComponentStory, ComponentMeta } from '@storybook/react';
import ConfirmDeleteEntity from './ConfirmDeleteEntity';

export default {
  title: `Dashboard/Core/Modal/ConfirmDeleteEntity`,
  component: ConfirmDeleteEntity,
  parameters: { layout: `fullscreen` },
} as ComponentMeta<typeof ConfirmDeleteEntity>;

const Template: ComponentStory<typeof ConfirmDeleteEntity> = (args) => (
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
