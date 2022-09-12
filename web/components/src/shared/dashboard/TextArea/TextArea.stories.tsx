import { ComponentStory, ComponentMeta } from '@storybook/react';
import TextArea from './TextArea';

export default {
  title: `Dashboard/Core/TextArea`,
  component: TextArea,
} as ComponentMeta<typeof TextArea>;

const Template: ComponentStory<typeof TextArea> = (args) => <TextArea {...args} />;

export const Default = Template.bind({});

export const WithPlaceholder = Template.bind({});
WithPlaceholder.args = {
  placeholder: `Write something nice`,
};

export const WithLabel = Template.bind({});
WithLabel.args = {
  label: `Something nice`,
};

export const WithBoth = Template.bind({});
WithBoth.args = {
  placeholder: `Write something nice`,
  label: `Something nice`,
};
