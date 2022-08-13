import { ComponentStory, ComponentMeta } from '@storybook/react';

import NoUsers from './NoUsers';

export default {
  title: `Dashboard/Users/NoUsers`,
  component: NoUsers,
} as ComponentMeta<typeof NoUsers>;

const Template: ComponentStory<typeof NoUsers> = (args) => <NoUsers {...args} />;

export const Default = Template.bind({});
