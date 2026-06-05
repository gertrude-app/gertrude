import { AmDoneScreen, ClaimScreen, ScreenShell } from '@dash/components';
import React, { useState } from 'react';
import type { AmDoneVariant } from '@dash/components';
import type { Meta, StoryObj } from '@storybook/react';
import { withStatefulChrome } from '../../decorators/StatefulChrome';

type ScreenStep = `claim` | `done`;

const ClaimAmDeviceScreen: React.FC<{
  code: string;
  modelName: string;
  iosVersion: string;
  childName: string;
  children: Array<{ id: string; name: string }>;
  initialStep: ScreenStep;
  doneVariant?: AmDoneVariant;
  accessEndsAt?: string;
  trialDaysRemaining?: number;
  error?: string;
}> = ({
  modelName,
  iosVersion,
  childName,
  children,
  initialStep,
  doneVariant = `notEntitled`,
  accessEndsAt,
  trialDaysRemaining,
  error,
}) => {
  const [step, setStep] = useState<ScreenStep>(initialStep);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const deviceType = modelName.toLowerCase().includes(`ipad`) ? `iPad` : `iPhone`;

  if (step === `claim`) {
    return (
      <ScreenShell title={`Connect ${deviceType}`}>
        <ClaimScreen
          children={children}
          deviceType={deviceType}
          modelName={modelName}
          iosVersion={iosVersion}
          onSubmit={() => {
            setIsSubmitting(true);
            setTimeout(() => {
              setIsSubmitting(false);
              setStep(`done`);
            }, 1000);
          }}
          onCancel={() => {}}
          isSubmitting={isSubmitting}
          error={error}
          app="podcasts"
        />
      </ScreenShell>
    );
  }

  return (
    <ScreenShell title={`${deviceType} Connected`}>
      <AmDoneScreen
        childName={childName}
        modelName={modelName}
        iosVersion={iosVersion}
        variant={doneVariant}
        accessEndsAt={accessEndsAt}
        trialDaysRemaining={trialDaysRemaining}
        onBackToDashboard={() => {}}
        onSubscribe={() => {}}
        onMaybeLater={() => {}}
      />
    </ScreenShell>
  );
};

const meta = {
  title: 'Dashboard/ClaimAmDevice/Screens', // eslint-disable-line
  component: ClaimAmDeviceScreen,
  decorators: [withStatefulChrome],
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof ClaimAmDeviceScreen>;

type Story = StoryObj<typeof ClaimAmDeviceScreen>;

export const ClaimWithChildren: Story = {
  args: {
    code: `847293`,
    modelName: `iPhone 14 Pro`,
    iosVersion: `18.2`,
    childName: `Emma`,
    children: [
      { id: `uuid-1`, name: `Luke` },
      { id: `uuid-2`, name: `Sarah` },
      { id: `uuid-3`, name: `Emma` },
    ],
    initialStep: `claim`,
  },
};

export const ClaimNoChildren: Story = {
  args: {
    code: `555444`,
    modelName: `iPad Pro 12.9-inch`,
    iosVersion: `18.2`,
    childName: ``,
    children: [],
    initialStep: `claim`,
  },
};

export const DoneTrialExpired: Story = {
  args: {
    code: `847293`,
    modelName: `iPhone 14 Pro`,
    iosVersion: `18.2`,
    childName: `Emma`,
    children: [],
    initialStep: `done`,
    doneVariant: `notEntitled`,
  },
};

export const DoneApproachingExpiry: Story = {
  args: {
    code: `847293`,
    modelName: `iPhone 14 Pro`,
    iosVersion: `18.2`,
    childName: `Emma`,
    children: [],
    initialStep: `done`,
    doneVariant: `approachingExpiry`,
    accessEndsAt: `June 27, 2026`,
  },
};

export const DoneActive: Story = {
  args: {
    code: `847293`,
    modelName: `iPhone 14 Pro`,
    iosVersion: `18.2`,
    childName: `Emma`,
    children: [],
    initialStep: `done`,
    doneVariant: `active`,
    trialDaysRemaining: 30,
  },
};

export default meta;
