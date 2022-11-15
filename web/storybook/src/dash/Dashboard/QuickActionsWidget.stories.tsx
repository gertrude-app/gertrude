import { QuickActionsWidget } from '@dash/components';
import type { ComponentStory, ComponentMeta } from '@storybook/react';

export default {
  title: 'Dashboard/Dashboard/Widgets/QuickActionsWidget', // eslint-disable-line
  component: QuickActionsWidget,
} as ComponentMeta<typeof QuickActionsWidget>;

const Template: ComponentStory<typeof QuickActionsWidget> = (args) => (
  <QuickActionsWidget {...args} />
);

export const Default = Template.bind({});
