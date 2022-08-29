import { ComponentStory, ComponentMeta } from '@storybook/react';
import KeyCreationStep from './KeyCreationStep';

export default {
  title: `KeyCreationStep`,
  component: KeyCreationStep,
} as ComponentMeta<typeof KeyCreationStep>;

const Template: ComponentStory<typeof KeyCreationStep> = (args) => (
  <KeyCreationStep {...args} />
);

export const Default = Template.bind({});
