import { ComponentStory, ComponentMeta } from '@storybook/react';
import KeyTypeOption from './KeyTypeOption';

export default {
  title: `Dashboard/Keychains/Keys/KeyTypeOption`,
  component: KeyTypeOption,
} as ComponentMeta<typeof KeyTypeOption>;

const Template: ComponentStory<typeof KeyTypeOption> = (args) => (
  <KeyTypeOption {...args} />
);

export const Unselected = Template.bind({});
Unselected.args = {
  icon: `globe-americas`,
  title: `Lorem ipsum`,
  description: `Lorem ipsum dolor sit amet consectetur adipisicing elit. Laboriosam quidem, cum veniam eos, similique animi impedit.`,
  selected: false,
};

export const Selected = Template.bind({});
Selected.args = {
  ...Unselected.args,
  selected: true,
};
