import { ContactStatusMessage } from '@marketing/components';
import type { ComponentStory, ComponentMeta } from '@storybook/react';

export default {
  title: `Marketing/ContactStatusMessage`,
  component: ContactStatusMessage,
} as ComponentMeta<typeof ContactStatusMessage>;

const Template: ComponentStory<typeof ContactStatusMessage> = (args) => (
  <ContactStatusMessage {...args} />
);

export const Info = Template.bind({});
Info.args = {
  type: `info`,
  heading: `Just FYI...`,
  message: `Lorem ipsum dolor sit amet consectetur adipisicing elit.`,
};

export const Success = Template.bind({});
Success.args = {
  type: `success`,
  heading: `Something went right!`,
  message: `Lorem ipsum dolor sit amet consectetur adipisicing elit.`,
};

export const Warning = Template.bind({});
Warning.args = {
  type: `warning`,
  heading: `Hmmm...`,
  message: `Lorem ipsum dolor sit amet consectetur adipisicing elit.`,
};

export const Error = Template.bind({});
Error.args = {
  type: `error`,
  heading: `Uh-oh, something awful happened`,
  message: `Lorem ipsum dolor sit amet consectetur adipisicing elit.`,
};
