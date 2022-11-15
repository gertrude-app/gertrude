import { Logo } from '@shared/components';
import type { ComponentStory, ComponentMeta } from '@storybook/react';

export default {
  title: 'Shared/Logo', // eslint-disable-line
  component: Logo,
  parameters: { layout: `fullscreen` },
} as ComponentMeta<typeof Logo>;

const Template: ComponentStory<typeof Logo> = (args) => <Logo {...args} />;

export const Default = Template.bind({});
Default.args = { type: `default`, size: 45 };
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
  size: 75,
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
  size: 40,
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
InvertedIconOnly.args = { ...Inverted.args, iconOnly: true };

export const InvertedLarge = Template.bind({});
InvertedLarge.decorators = Inverted.decorators;
InvertedLarge.args = { ...Inverted.args, iconOnly: true, size: 65 };

export const Dark = Template.bind({});
Dark.args = {
  type: `on-dark`,
  iconOnly: false,
  size: 40,
};
Dark.decorators = [
  (Story) => (
    <div className="py-8 bg-gray-900 flex justify-center">
      <Story />
    </div>
  ),
];

export const DarkIconOnly = Template.bind({});
DarkIconOnly.decorators = Dark.decorators;
DarkIconOnly.args = { ...Dark.args, iconOnly: true };

export const DarkLarge = Template.bind({});
DarkLarge.decorators = Dark.decorators;
DarkLarge.args = { ...Dark.args, iconOnly: true, size: 65 };
