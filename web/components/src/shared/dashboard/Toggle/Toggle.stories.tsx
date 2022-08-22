import { ComponentStory, ComponentMeta } from '@storybook/react';

import Toggle from './Toggle';

export default {
  title: `Dashboard/Core/Toggle`,
  component: Toggle,
} as ComponentMeta<typeof Toggle>;

const Template: ComponentStory<typeof Toggle> = (args) => (
  <div className="flex flex-col space-y-4">
    <Toggle {...args} enabled={true} />
    <Toggle {...args} enabled={false} />
  </div>
);

export const Default = Template.bind({});
