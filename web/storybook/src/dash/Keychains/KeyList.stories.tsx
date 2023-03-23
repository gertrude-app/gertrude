import { KeyList } from '@dash/components';
import type { StoryFn, ComponentMeta } from '@storybook/react';
import { keyExamples } from '../../story-helpers';

export default {
  title: 'Dashboard/Keychains/KeyList', // eslint-disable-line
  component: KeyList,
} as ComponentMeta<typeof KeyList>;

const Template: StoryFn<typeof KeyList> = (args) => <KeyList {...args} />;

// @screenshot: xs/400,md/400
export const Default = Template.bind({});
Default.args = {
  keys: Object.values(keyExamples),
};
