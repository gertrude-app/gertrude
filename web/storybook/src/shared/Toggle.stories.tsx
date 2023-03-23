import { Toggle } from '@shared/components';
import type { StoryFn, ComponentMeta } from '@storybook/react';

export default {
  title: 'Dashboard/Forms/Toggle', // eslint-disable-line
  component: Toggle,
} as ComponentMeta<typeof Toggle>;

const Template: StoryFn<typeof Toggle> = (args) => (
  <div className="flex flex-col space-y-4">
    <Toggle {...args} enabled={true} />
    <Toggle {...args} enabled={false} />
  </div>
);

export const Default = Template.bind({});
