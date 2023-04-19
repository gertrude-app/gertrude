import { RadioGroup } from '@dash/components';
import type { StoryObj, Meta } from '@storybook/react';
import { props } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Forms/RadioGroup', // eslint-disable-line
  component: RadioGroup,
} satisfies Meta<typeof RadioGroup>;

type Story = StoryObj<typeof meta>;

export const Default: Story = props({
  options: [
    { display: `Option 1`, value: `option1` },
    { display: `Option 2`, value: `option2` },
  ],
  selectedOption: `option1`,
});

export default meta;
