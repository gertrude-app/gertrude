import type { Meta, StoryObj } from '@storybook/react';
import { appWindow, props } from '../story-helpers';
import OnboardingStatefulSwitcher from './OnboardingStatefulSwitcher';

const meta = {
  title: 'MacOS App/Onboarding/Transitions',
  component: OnboardingStatefulSwitcher,
  ...appWindow(900, 700),
} satisfies Meta<typeof OnboardingStatefulSwitcher>;

type Story = StoryObj<typeof meta>;

export const StatefulSwitcher: Story = props({});
export default meta;
