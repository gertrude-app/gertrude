import { Logo } from '@shared/components';
import type { ComponentStory, ComponentMeta } from '@storybook/react';

export default {
  title: 'Shared/Logo', // eslint-disable-line
  component: Logo,
  parameters: { layout: `fullscreen` },
} as ComponentMeta<typeof Logo>;

const Template: ComponentStory<typeof Logo> = (args) => <Logo {...args} />;

export const Default = Template.bind({});
Default.args = { type: `default` };
Default.decorators = [
  (Story) => (
    <div className="py-8 flex justify-center">
      <Story />
    </div>
  ),
];

export const DefaultIconOnly = Template.bind({});
DefaultIconOnly.args = {
  type: `default`,
  iconOnly: true,
  size: 90,
};
DefaultIconOnly.decorators = [
  (Story) => (
    <div className="py-8 flex justify-center">
      <Story />
    </div>
  ),
];

export const Inverted = Template.bind({});
Inverted.args = {
  type: `inverted`,
  iconOnly: false,
};
Inverted.decorators = [
  (Story) => (
    <div className="py-8 bg-violet-500 flex justify-center">
      <Story />
    </div>
  ),
];

export const InvertedIconOnly = Template.bind({});
InvertedIconOnly.decorators = Inverted.decorators;
InvertedIconOnly.args = { ...Inverted.args, iconOnly: true, size: 90 };
