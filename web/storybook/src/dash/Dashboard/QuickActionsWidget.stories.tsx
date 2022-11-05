import { ComponentStory, ComponentMeta } from '@storybook/react';
import { QuickActionsWidget } from '@dash/components';

export default {
  title: `Dashboard/Dashboard/Widgets/QuickActionsWidget`,
  component: QuickActionsWidget,
} as ComponentMeta<typeof QuickActionsWidget>;

const Template: ComponentStory<typeof QuickActionsWidget> = (args) => (
  <QuickActionsWidget {...args} />
);

export const Default = Template.bind({});
