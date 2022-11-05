import { Toggle } from '@dash/components';
import type { ComponentStory, ComponentMeta } from '@storybook/react';

export default {
  title: `Dashboard/Forms/Toggle`,
  component: Toggle,
} as ComponentMeta<typeof Toggle>;

const Template: ComponentStory<typeof Toggle> = (args) => (
  <div className="flex flex-col space-y-4">
    <Toggle {...args} enabled={true} />
    <Toggle {...args} enabled={false} />
  </div>
);

export const Default = Template.bind({});
