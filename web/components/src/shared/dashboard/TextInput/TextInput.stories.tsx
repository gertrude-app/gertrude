import { ComponentStory, ComponentMeta } from '@storybook/react';

import TextInput from './TextInput';

export default {
  title: `Dashboard/Core/TextInput`,
  component: TextInput,
} as ComponentMeta<typeof TextInput>;

const Template: ComponentStory<typeof TextInput> = (args) => (
  <div>
    <TextInput {...args} className="max-w-sm" />
    <TextInput {...args} className="mt-5" />
  </div>
);

export const Default = Template.bind({});
Default.args = {
  type: `email`,
  label: `Email address`,
  placeholder: `you@example.com`,
};

export const WithUnit = Template.bind({});
WithUnit.args = {
  type: `email`,
  label: `Interval`,
  unit: 'seconds',
};
