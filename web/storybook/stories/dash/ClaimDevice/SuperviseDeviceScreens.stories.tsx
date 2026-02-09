import { ChildAssignmentPicker, DeviceContextBanner } from '@dash/components';
import React, { useState } from 'react';
import type { Meta, StoryObj } from '@storybook/react';
import {
  DoneScreen,
  DownloadHelperScreen,
  PaymentGateScreen,
  ScreenShell,
  SuperviseScreen,
  WindowsSmartScreenModal,
} from '../../../../dash/app/src/components/routes/SuperviseDevice/screens';
import { withStatefulChrome } from '../../decorators/StatefulChrome';

type ScreenStep = `claim` | `payment` | `download` | `supervise` | `done`;

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
        <div className="mb-4">
          <DeviceContextBanner
            modelName={modelName}
            iosVersion={iosVersion}
            label={`Adding ${deviceType}:`}
          />
        </div>
        <div className="mb-6 pb-6 border-b border-slate-100">
          <p className="text-sm text-slate-500 mb-1">Claim code</p>
          <p className="text-2xl font-mono font-semibold text-slate-800 tracking-wider">
            {code}
          </p>
        </div>
        <ChildAssignmentPicker
          children={children}
          deviceType={deviceType}
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
        <PaymentGateScreen
          childName={childName}
          modelName={modelName}
          iosVersion={iosVersion}
          deviceType={deviceType}
          onSubscribe={() => setStep(`download`)}
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
          onNext={() => setStep(`supervise`)}
          initialDownloaded={initialDownloaded}
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
      />
    </ScreenShell>
  );
};

const meta = {
  title: 'Dashboard/SuperviseDevice/Screens', // eslint-disable-line
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

export const DownloadHelperStep1: Story = {
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

export const DownloadHelperStep2: Story = {
  args: {
    code: `847293`,
    modelName: `iPhone 15`,
    iosVersion: `18.2`,
    childName: `Emma`,
    children: [],
    initialStep: `download`,
    initialDownloaded: true,
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

export const WindowsSmartScreenInterstitial: StoryObj = {
  render: () => (
    <div className="relative w-full h-[500px] bg-slate-100">
      <WindowsSmartScreenModal onCancel={() => {}} onDownload={() => {}} />
    </div>
  ),
  parameters: { layout: `centered` },
};

export default meta;
