import { ComponentStory, ComponentMeta } from '@storybook/react';
import { TextInput } from '@shared/components';

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
  type: `positiveInteger`,
  label: `Interval`,
  unit: `seconds`,
};

export const WithPrefix = Template.bind({});
WithPrefix.args = {
  type: `text`,
  label: `URL`,
  prefix: `https://`,
};

export const WithUnitAndPrefix = Template.bind({});
WithUnitAndPrefix.args = {
  ...WithPrefix.args,
  label: `Web address`,
  unit: `.com`,
};
