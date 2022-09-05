import { ComponentStory, ComponentMeta } from '@storybook/react';
import KeyCreator from './KeyCreator';

export default {
  title: `Dashboard/Keys/KeyCreator`,
  component: KeyCreator,
} as ComponentMeta<typeof KeyCreator>;

const Template: ComponentStory<typeof KeyCreator> = (args) => <KeyCreator {...args} />;

export const Create = Template.bind({});
Create.args = {
  mode: `create`,
};
