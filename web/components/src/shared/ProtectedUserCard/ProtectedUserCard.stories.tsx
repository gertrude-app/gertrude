import { ComponentStory, ComponentMeta } from '@storybook/react';

import ProtectedUserCard from './ProtectedUserCard';

export default {
  title: 'ProtectedUserCard',
  component: ProtectedUserCard,
} as ComponentMeta<typeof ProtectedUserCard>;

const Template: ComponentStory<typeof ProtectedUserCard> = (args) => <ProtectedUserCard {...args} />;

export const Default = Template.bind({});
