import { PageHeading } from '@dash/components';
import type { ComponentStory, ComponentMeta } from '@storybook/react';

export default {
  title: `Dashboard/Core/PageHeading`,
  component: PageHeading,
} as ComponentMeta<typeof PageHeading>;

const Template: ComponentStory<typeof PageHeading> = (args) => <PageHeading {...args} />;

export const Default = Template.bind({});
Default.args = {
  children: `Profile`,
  icon: `user`,
};
