import { SelectMenu } from '@dash/components';
import type { StoryFn, ComponentMeta } from '@storybook/react';

export default {
  title: 'Dashboard/Forms/SelectMenu', // eslint-disable-line
  component: SelectMenu,
} as ComponentMeta<typeof SelectMenu>;

const Template: StoryFn<typeof SelectMenu> = (args) => <SelectMenu {...args} />;

export const Default = Template.bind({});
Default.args = {
  options: [
    { value: `1`, display: `Do this` },
    { value: `2`, display: `Do that` },
    { value: `3`, display: `Do the other thing` },
  ],
  selectedOption: `Do this`,
};

export const Deemphasized = Template.bind({});
Deemphasized.args = {
  ...Default.args,
  deemphasized: true,
};
