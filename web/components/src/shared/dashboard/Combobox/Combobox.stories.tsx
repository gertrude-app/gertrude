import { ComponentStory, ComponentMeta } from '@storybook/react';
import Combobox from './Combobox';

export default {
  title: `Dashboard/Core/Combobox`,
  component: Combobox,
} as ComponentMeta<typeof Combobox>;

const Template: ComponentStory<typeof Combobox> = (args) => <Combobox {...args} />;

export const Default = Template.bind({});
Default.args = {
  options: [
    { name: `Slack`, id: `app-1` },
    { name: `Chrome`, id: `app-2` },
    { name: `Figma`, id: `app-3` },
    { name: `Notes`, id: `app-4` },
    { name: `Firefox`, id: `app-5` },
    { name: `VSCode`, id: `app-6` },
    { name: `Skype`, id: `app-7` },
    { name: `Sketch`, id: `app-8` },
    { name: `Photoshop`, id: `app-9` },
    { name: `Safari`, id: `app-10` },
    { name: `Calendar`, id: `app-11` },
    { name: `Brave`, id: `app-12` },
    { name: `Edge`, id: `app-13` },
    { name: `MatLab`, id: `app-14` },
    { name: `Microsoft Teams`, id: `app-15` },
  ],
  selectedOption: { name: `Slack`, id: `app-1` },
};
