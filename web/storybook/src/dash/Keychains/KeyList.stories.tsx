import { ComponentStory, ComponentMeta } from '@storybook/react';
import { KeyList } from '@dash/components';
import { keyExamples } from '../../story-helpers';

export default {
  title: `Dashboard/Keychains/KeyList`,
  component: KeyList,
} as ComponentMeta<typeof KeyList>;

const Template: ComponentStory<typeof KeyList> = (args) => <KeyList {...args} />;

export const Default = Template.bind({});
Default.args = {
  keys: Object.values(keyExamples),
};
