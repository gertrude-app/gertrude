import { Combobox } from '@dash/components';
import type { StoryObj, Meta } from '@storybook/react';
import { props } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Forms/Combobox', // eslint-disable-line
  component: Combobox,
} satisfies Meta<typeof Combobox>;

type Story = StoryObj<typeof meta>;

export const Selected: Story = props({
  options: [
    { display: `Slack`, value: `app-1` },
    { display: `Chrome`, value: `app-2` },
    { display: `Figma`, value: `app-3` },
    { display: `Notes`, value: `app-4` },
    { display: `Firefox`, value: `app-5` },
    { display: `VSCode`, value: `app-6` },
    { display: `Skype`, value: `app-7` },
    { display: `Sketch`, value: `app-8` },
    { display: `Photoshop`, value: `app-9` },
    { display: `Safari`, value: `app-10` },
    { display: `Calendar`, value: `app-11` },
    { display: `Brave`, value: `app-12` },
    { display: `Edge`, value: `app-13` },
    { display: `MatLab`, value: `app-14` },
    { display: `Microsoft Teams`, value: `app-15` },
  ],
  selected: { display: `Slack`, value: `app0` },
  setSelected: () => {},
});

export const EmptySelected: Story = props({
  ...Selected.args,
  selected: { display: ``, value: `` },
});

export default meta;
