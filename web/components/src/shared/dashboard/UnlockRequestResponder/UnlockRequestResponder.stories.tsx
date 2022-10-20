import { ComponentStory, ComponentMeta } from '@storybook/react';
import UnlockRequestResponder from './UnlockRequestResponder';
import { time } from '../story-helpers';

export default {
  title: `Dashboard/Users/UnlockRequestResponder`,
  component: UnlockRequestResponder,
} as ComponentMeta<typeof UnlockRequestResponder>;

const Template: ComponentStory<typeof UnlockRequestResponder> = (args) => (
  <UnlockRequestResponder {...args} />
);

export const FirstStep = Template.bind({});
FirstStep.args = {
  isOpen: true,
  step: `preview request`,
  userName: `Winfield`,
  comment: `schedule mayra appointments`,
  target: {
    url: `https://cdn-s.acuityscheduling.com/logo24613730.jpg?1650316493&whiteBg=1&rectangular=1`,
    domain: `cdn-s.acuityscheduling.com`,
    IPAddress: `151.101.2.132`,
  },
  dateRequested: new Date(time.subtracting({ minutes: 36 })),
  appName: `Safari Browser`,
  appCategory: `browser`,
  appBundleId: `.com.apple.Safari`,
  protocol: `TCP`,
};

export const SecondStep = Template.bind({});
SecondStep.args = {
  ...FirstStep.args,
  step: `create key`,
};

export const ThirdStep = Template.bind({});
ThirdStep.args = {
  ...FirstStep.args,
  step: `select keychain`,
};
