import { ComponentStory, ComponentMeta } from '@storybook/react';
import UnlockRequestsWidget from './UnlockRequestsWidget';

export default {
  title: `UnlockRequestsWidget`,
  component: UnlockRequestsWidget,
} as ComponentMeta<typeof UnlockRequestsWidget>;

const Template: ComponentStory<typeof UnlockRequestsWidget> = (args) => (
  <UnlockRequestsWidget {...args} />
);

export const Default = Template.bind({});
