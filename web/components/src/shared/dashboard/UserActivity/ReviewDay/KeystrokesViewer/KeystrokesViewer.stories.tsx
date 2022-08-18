import { ComponentStory, ComponentMeta } from '@storybook/react';

import KeystrokesViewer from './KeystrokesViewer';

export default {
  title: `Dashboard/UserActivity/KeystrokesViewer`,
  component: KeystrokesViewer,
} as ComponentMeta<typeof KeystrokesViewer>;

const Template: ComponentStory<typeof KeystrokesViewer> = (args) => (
  <KeystrokesViewer {...args} />
);

export const Basic = Template.bind({});
Basic.args = {
  strokes: `Dearest digital diary,\nsSorry it's been so long. I'll try to right more.\nUntil tomorrow.`,
  date: new Date(),
  application: `Notes`,
};

export const Short = Template.bind({});
Short.args = {
  strokes: `9 - 3 = 4`,
  date: new Date(),
  application: `Notes`,
};

export const Long = Template.bind({});
Long.args = {
  strokes: `Four score and seven years ago our fathers brought forth on this continent, a new nation, conceived in Liberty, and dedicated to the proposition that all men are created equal. Lorem ipsum, dolor sit amet consectetur adipisicing elit. Molestias fugit, officiis ut aliquam molestiae alias. Recusandae reprehenderit reiciendis voluptas facere similique dolor pariatur nemo, possimus saepe in voluptatem dolore esse.`,
  date: new Date(),
  application: `Notes`,
};
