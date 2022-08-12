import { ComponentStory, ComponentMeta } from '@storybook/react';

import NoUsers from './NoUsers';

export default {
  title: `NoUsers`,
  component: NoUsers,
} as ComponentMeta<typeof NoUsers>;

const Template: ComponentStory<typeof NoUsers> = (args) => <NoUsers {...args} />;

export const Default = Template.bind({});
