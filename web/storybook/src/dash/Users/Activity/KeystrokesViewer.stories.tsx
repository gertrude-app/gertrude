import { KeystrokesViewer } from '@dash/components';
import type { StoryObj, Meta } from '@storybook/react';
import { time, props } from '../../../story-helpers';

const meta = {
  title: 'Dashboard/Users/Activity/KeystrokesViewer', // eslint-disable-line
  component: KeystrokesViewer,
} satisfies Meta<typeof KeystrokesViewer>;

type Story = StoryObj<typeof meta>;

export const Basic: Story = props({
  strokes: `Dearest digital diary,\nsSorry it's been so long. I'll try to right more.\nUntil tomorrow.`,
  date: new Date(time.stable()),
  application: `Notes`,
  duringSuspension: false,
});

export const Short: Story = props({
  ...Basic.args,
  strokes: `9 - 3 = 4`,
});

export const Long: Story = props({
  ...Basic.args,
  strokes: `Four score and seven years ago our fathers brought forth on this continent, a new nation, conceived in Liberty, and dedicated to the proposition that all men are created equal. Lorem ipsum, dolor sit amet consectetur adipisicing elit. Molestias fugit, officiis ut aliquam molestiae alias. Recusandae reprehenderit reiciendis voluptas facere similique dolor pariatur nemo, possimus saepe in voluptatem dolore esse.`,
});

export default meta;
