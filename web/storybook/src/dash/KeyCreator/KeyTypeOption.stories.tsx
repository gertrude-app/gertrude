import { KeyTypeOption } from '@dash/components';
import type { ComponentStory, ComponentMeta } from '@storybook/react';

export default {
  title: `Dashboard/KeyCreator/KeyTypeOption`,
  component: KeyTypeOption,
} as ComponentMeta<typeof KeyTypeOption>;

const Template: ComponentStory<typeof KeyTypeOption> = (args) => (
  <KeyTypeOption {...args} />
);

export const Unselected = Template.bind({});
Unselected.args = {
  icon: `globe`,
  title: `Lorem ipsum`,
  description: `Lorem ipsum dolor sit amet consectetur adipisicing elit. Laboriosam quidem, cum veniam eos, similique animi impedit.`,
  selected: false,
};

export const Selected = Template.bind({});
Selected.args = {
  ...Unselected.args,
  selected: true,
};
