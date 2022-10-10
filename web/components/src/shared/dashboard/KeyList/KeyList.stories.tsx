import { ComponentStory, ComponentMeta } from '@storybook/react';
import { keyExamples } from '../story-helpers';
import KeyList from './KeyList';

export default {
  title: `Dashboard/Keychains/Keys/KeyList`,
  component: KeyList,
} as ComponentMeta<typeof KeyList>;

const Template: ComponentStory<typeof KeyList> = (args) => <KeyList {...args} />;

export const Default = Template.bind({});
Default.args = {
  keys: Object.values(keyExamples),
};
