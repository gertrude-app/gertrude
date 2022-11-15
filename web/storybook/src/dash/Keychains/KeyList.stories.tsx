import { KeyList } from '@dash/components';
import type { ComponentStory, ComponentMeta } from '@storybook/react';
import { keyExamples } from '../../story-helpers';

export default {
  title: 'Dashboard/Keychains/KeyList', // eslint-disable-line
  component: KeyList,
} as ComponentMeta<typeof KeyList>;

const Template: ComponentStory<typeof KeyList> = (args) => <KeyList {...args} />;

export const Default = Template.bind({});
Default.args = {
  keys: Object.values(keyExamples),
};
