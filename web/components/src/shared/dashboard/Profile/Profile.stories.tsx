import { ComponentStory, ComponentMeta } from '@storybook/react';
import { withStatefulChrome } from '../../../decorators/StatefulChrome';
import Profile from './Profile';

export default {
  title: `Dashboard/Profile`,
  component: Profile,
  parameters: { layout: `fullscreen` },
  decorators: [withStatefulChrome],
} as ComponentMeta<typeof Profile>;

const Template: ComponentStory<typeof Profile> = (args) => <Profile {...args} />;

export const Default = Template.bind({});
Default.args = {
  email: `johndoe@example.com`,
  status: `active`,
  methods: [
    { id: `1`, method: `email`, value: `me@example.com` },
    { id: `2`, method: `slack`, value: `#Gertrude` },
    { id: `3`, method: `email`, value: `you@example.com` },
    { id: `4`, method: `text`, value: `(123) 456-7890` },
  ],
  notifications: [
    { id: `1`, method: `email`, value: `me@example.com`, when: `suspension requests` },
    { id: `2`, method: `slack`, value: `#homework`, when: `unlock requests` },
    { id: `3`, method: `text`, value: `(123) 456-7890`, when: `suspension requests` },
  ],
};
