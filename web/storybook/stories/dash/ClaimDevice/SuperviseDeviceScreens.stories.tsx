import { ClaimScreen, PlanGateScreen, ScreenShell } from '@dash/components';
import React, { useState } from 'react';
import type { Meta, StoryObj } from '@storybook/react';
import {
  DoneScreen,
  DownloadHelperScreen,
  LaunchHelperScreen,
  SuperviseScreen,
} from '../../../../dash/app/src/components/routes/SuperviseDevice/screens';
import { withStatefulChrome } from '../../decorators/StatefulChrome';

type ScreenStep = `claim` | `payment` | `download` | `launch` | `supervise` | `done`;

const SuperviseDeviceScreen: React.FC<{
  code: string;
  modelName: string;
  iosVersion: string;
  childName: string;
  children: Array<{ id: string; name: string }>;
  initialStep: ScreenStep;
  initialDownloaded?: boolean;
  initialCopied?: boolean;
  checkoutCancelled?: boolean;
  error?: string;
}> = ({
  code,
  modelName,
  iosVersion,
  childName,
  children,
  initialStep,
  initialDownloaded = false,
  initialCopied = false,
  checkoutCancelled = false,
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
              setStep(`payment`);
            }, 1000);
          }}
          onCancel={() => {}}
          isSubmitting={isSubmitting}
          error={error}
        />
      </ScreenShell>
    );
  }

  if (step === `payment`) {
    return (
      <ScreenShell title={`Continue ${deviceType} Setup`}>
        <PlanGateScreen
          icon="credit-card"
          subtitle={`Setting up ${childName}'s ${modelName} · iOS ${iosVersion}`}
          message={
            <>
              To supervise and manage {childName}'s {deviceType}, you’ll need a{` `}
              <b>Gertrude subscription.</b>
            </>
          }
          extraBullets={[`All basic iOS blocking (GIFs, Apple Maps, Spotify etc.)`]}
          onPrimary={() => setStep(`download`)}
          primaryLabel="Subscribe — $10/year"
          checkoutCancelled={checkoutCancelled}
        />
      </ScreenShell>
    );
  }

  if (step === `download`) {
    return (
      <ScreenShell title={`Continue ${deviceType} Setup`}>
        <DownloadHelperScreen
          childName={childName}
          modelName={modelName}
          iosVersion={iosVersion}
          onDownload={() => {}}
          onNext={() => setStep(`launch`)}
          initialDownloaded={initialDownloaded}
        />
      </ScreenShell>
    );
  }

  if (step === `launch`) {
    return (
      <ScreenShell title={`Continue ${deviceType} Setup`}>
        <LaunchHelperScreen
          childName={childName}
          modelName={modelName}
          iosVersion={iosVersion}
          onNext={() => setStep(`supervise`)}
        />
      </ScreenShell>
    );
  }

  if (step === `supervise`) {
    return (
      <ScreenShell title={`Continue ${deviceType} Setup`}>
        <SuperviseScreen
          childName={childName}
          modelName={modelName}
          iosVersion={iosVersion}
          code={parseInt(code, 10)}
          onDone={() => setStep(`done`)}
          initialCopied={initialCopied}
        />
      </ScreenShell>
    );
  }

  return (
    <ScreenShell title={`${deviceType} Setup Complete`}>
      <DoneScreen
        childName={childName}
        modelName={modelName}
        iosVersion={iosVersion}
        deviceId="mock-device-id"
        childId="mock-child-id"
      />
    </ScreenShell>
  );
};

const meta = {
  title: 'Dashboard/SuperviseDevice/Screens',
  component: SuperviseDeviceScreen,
  decorators: [withStatefulChrome],
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof SuperviseDeviceScreen>;

type Story = StoryObj<typeof SuperviseDeviceScreen>;

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

export const PaymentGate: Story = {
  args: {
    code: `847293`,
    modelName: `iPhone 15`,
    iosVersion: `18.2`,
    childName: `Emma`,
    children: [],
    initialStep: `payment`,
  },
};

export const PaymentGateCancelled: Story = {
  args: {
    code: `847293`,
    modelName: `iPhone 15`,
    iosVersion: `18.2`,
    childName: `Emma`,
    children: [],
    initialStep: `payment`,
    checkoutCancelled: true,
  },
};

export const DownloadHelper: Story = {
  args: {
    code: `847293`,
    modelName: `iPhone 15`,
    iosVersion: `18.2`,
    childName: `Emma`,
    children: [],
    initialStep: `download`,
    initialDownloaded: false,
  },
};

export const LaunchHelper: Story = {
  args: {
    code: `847293`,
    modelName: `iPhone 15`,
    iosVersion: `18.2`,
    childName: `Emma`,
    children: [],
    initialStep: `launch`,
  },
};

export const SuperviseStep1: Story = {
  args: {
    code: `847293`,
    modelName: `iPhone 15`,
    iosVersion: `18.2`,
    childName: `Emma`,
    children: [],
    initialStep: `supervise`,
    initialCopied: false,
  },
};

export const SuperviseStep2: Story = {
  args: {
    code: `847293`,
    modelName: `iPhone 15`,
    iosVersion: `18.2`,
    childName: `Emma`,
    children: [],
    initialStep: `supervise`,
    initialCopied: true,
  },
};

export const Done: Story = {
  args: {
    code: `847293`,
    modelName: `iPhone 15`,
    iosVersion: `18.2`,
    childName: `Emma`,
    children: [],
    initialStep: `done`,
  },
};

export default meta;
