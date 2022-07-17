import { ComponentStory, ComponentMeta } from '@storybook/react';

import SelectMenu from './SelectMenu';

export default {
  title: 'SelectMenu',
  component: SelectMenu,
} as ComponentMeta<typeof SelectMenu>;

const Template: ComponentStory<typeof SelectMenu> = (args) => <SelectMenu {...args} />;

export const Default = Template.bind({});

Default.args = {
  options: ['Do this', 'Do that', 'Do the other thing'],
  whichSelected: 'Do this',
};
