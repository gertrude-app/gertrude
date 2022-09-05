import { ComponentStory, ComponentMeta } from '@storybook/react';
import KeyCreationStep from './KeyCreationStep';

export default {
  title: `Dashboard/Keys/KeyCreationStep`,
  component: KeyCreationStep,
} as ComponentMeta<typeof KeyCreationStep>;

const Template: ComponentStory<typeof KeyCreationStep> = (args) => (
  <KeyCreationStep {...args} />
);

export const Enabled = Template.bind({});
Enabled.args = {
  title: <h1>Lorem ipsum</h1>,
  currentStep: 1,
  index: 1,
  children: <div>html goes here</div>,
  numSteps: 1,
  stepName: `Lorem ipsum`,
  mode: `create`,
};

export const Disabled = Template.bind({});
Disabled.args = {
  title: <h1>Lorem ipsum</h1>,
  currentStep: 1,
  index: 2,
  children: <div>html goes here</div>,
  numSteps: 2,
  stepName: `Lorem ipsum`,
  mode: `create`,
};
