import { KeystrokesViewer } from '@dash/components';
import type { StoryFn, ComponentMeta } from '@storybook/react';
import { time } from '../../../story-helpers';

export default {
  title: 'Dashboard/Users/Activity/KeystrokesViewer', // eslint-disable-line
  component: KeystrokesViewer,
} as ComponentMeta<typeof KeystrokesViewer>;

const Template: StoryFn<typeof KeystrokesViewer> = (args) => (
  <KeystrokesViewer {...args} />
);

export const Basic = Template.bind({});
Basic.args = {
  strokes: `Dearest digital diary,\nsSorry it's been so long. I'll try to right more.\nUntil tomorrow.`,
  date: new Date(time.stable()),
  application: `Notes`,
};

export const Short = Template.bind({});
Short.args = {
  ...Basic.args,
  strokes: `9 - 3 = 4`,
};

export const Long = Template.bind({});
Long.args = {
  ...Basic.args,
  strokes: `Four score and seven years ago our fathers brought forth on this continent, a new nation, conceived in Liberty, and dedicated to the proposition that all men are created equal. Lorem ipsum, dolor sit amet consectetur adipisicing elit. Molestias fugit, officiis ut aliquam molestiae alias. Recusandae reprehenderit reiciendis voluptas facere similique dolor pariatur nemo, possimus saepe in voluptatem dolore esse.`,
};
