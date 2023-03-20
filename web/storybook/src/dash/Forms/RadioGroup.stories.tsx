import { RadioGroup } from '@dash/components';
import type { StoryFn, ComponentMeta } from '@storybook/react';

export default {
  title: 'Dashboard/Forms/RadioGroup', // eslint-disable-line
  component: RadioGroup,
} as ComponentMeta<typeof RadioGroup>;

const Template: StoryFn<typeof RadioGroup> = (args) => <RadioGroup {...args} />;

export const Default = Template.bind({});
Default.args = {
  options: [
    { display: `Option 1`, value: `option1` },
    { display: `Option 2`, value: `option2` },
  ],
  selectedOption: `option1`,
};
