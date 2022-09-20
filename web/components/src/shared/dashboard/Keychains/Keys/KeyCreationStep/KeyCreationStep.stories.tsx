import { ComponentStory, ComponentMeta } from '@storybook/react';
import KeyCreationStep from './KeyCreationStep';

export default {
  title: `Dashboard/Keychains/Keys/KeyCreationStep`,
  component: KeyCreationStep,
} as ComponentMeta<typeof KeyCreationStep>;

const Template: ComponentStory<typeof KeyCreationStep> = (args) => (
  <KeyCreationStep {...args} />
);

export const Open = Template.bind({});
Open.args = {
  mode: `edit`,
  activeTitle: `Add an optional widget:`,
  lookaheadTitle: `Do something`,
  title: <h1>Lorem ipsum</h1>,
  currentStep: 1,
  index: 1,
  children: <div>some html goes here</div>,
  isLast: false,
  setCurrentStep: () => {},
  canAdvance: true,
};

export const Closed = Template.bind({});
Closed.args = {
  ...Open.args,
  index: 2,
};
