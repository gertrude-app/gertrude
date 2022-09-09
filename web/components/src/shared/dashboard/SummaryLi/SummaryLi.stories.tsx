import { ComponentStory, ComponentMeta } from '@storybook/react';
import SummaryLi from './SummaryLi';

export default {
  title: `SummaryLi`,
  component: SummaryLi,
} as ComponentMeta<typeof SummaryLi>;

const Template: ComponentStory<typeof SummaryLi> = (args) => <SummaryLi {...args} />;

export const Default = Template.bind({});
