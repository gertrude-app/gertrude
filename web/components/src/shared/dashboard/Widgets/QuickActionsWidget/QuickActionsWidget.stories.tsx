import { ComponentStory, ComponentMeta } from '@storybook/react';
import QuickActionsWidget from './QuickActionsWidget';

export default {
  title: `QuickActionsWidget`,
  component: QuickActionsWidget,
} as ComponentMeta<typeof QuickActionsWidget>;

const Template: ComponentStory<typeof QuickActionsWidget> = (args) => <QuickActionsWidget {...args} />;

export const Default = Template.bind({});
