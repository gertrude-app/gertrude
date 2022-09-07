import { ComponentStory, ComponentMeta } from '@storybook/react';
import KeyScopeRadioOption from './KeyScopeRadioOption';

export default {
  title: `KeyScopeRadioOption`,
  component: KeyScopeRadioOption,
} as ComponentMeta<typeof KeyScopeRadioOption>;

const Template: ComponentStory<typeof KeyScopeRadioOption> = (args) => (
  <KeyScopeRadioOption {...args} />
);

export const Default = Template.bind({});
