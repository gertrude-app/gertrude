import {
  ChildAssignmentPicker,
  DeviceContextBanner,
  PageHeading,
} from '@dash/components';
import { Button } from '@shared/components';
import React, { useState } from 'react';
import type { Meta, StoryObj } from '@storybook/react';
import {
  DownloadHelperScreen,
  ProgressDots,
  SuperviseScreen,
  WindowsSmartScreenModal,
} from '../../../../dash/app/src/components/routes/SuperviseDevice/screens';
import { withStatefulChrome } from '../../decorators/StatefulChrome';

type ScreenStep = `claim` | `download` | `supervise` | `done`;

const SuperviseDeviceScreen: React.FC<{
  code: string;
  modelName: string;
  iosVersion: string;
  childName: string;
  children: Array<{ id: string; name: string }>;
  initialStep: ScreenStep;
  initialDownloaded?: boolean;
  initialCopied?: boolean;
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
  error,
}) => {
  const [step, setStep] = useState<ScreenStep>(initialStep);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const deviceType = modelName.toLowerCase().includes(`ipad`) ? `iPad` : `iPhone`;

  if (step === `claim`) {
    return (
      <div className="relative max-w-3xl">
        <PageHeading icon="phone">Connect {deviceType}</PageHeading>
        <div className="mt-8 bg-white rounded-2xl border border-slate-200 p-6">
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
            onSubmit={() => {
              setIsSubmitting(true);
              setTimeout(() => {
                setIsSubmitting(false);
                setStep(`download`);
              }, 1000);
            }}
            onCancel={() => {}}
            isSubmitting={isSubmitting}
            error={error}
          />
        </div>
      </div>
    );
  }

  if (step === `download`) {
    return (
      <div className="relative max-w-3xl">
        <PageHeading icon="phone">Continue {deviceType} Setup</PageHeading>
        <div className="mt-8 bg-white rounded-2xl border border-slate-200 p-6">
          <DownloadHelperScreen
            childName={childName}
            modelName={modelName}
            iosVersion={iosVersion}
            onDownload={() => {}}
            onNext={() => setStep(`supervise`)}
            initialDownloaded={initialDownloaded}
          />
        </div>
      </div>
    );
  }

  if (step === `supervise`) {
    return (
      <div className="relative max-w-3xl">
        <PageHeading icon="phone">Continue {deviceType} Setup</PageHeading>
        <div className="mt-8 bg-white rounded-2xl border border-slate-200 p-6">
          <SuperviseScreen
            childName={childName}
            modelName={modelName}
            iosVersion={iosVersion}
            code={parseInt(code, 10)}
            onDone={() => setStep(`done`)}
            initialCopied={initialCopied}
          />
        </div>
      </div>
    );
  }

  return (
    <div className="relative max-w-3xl">
      <PageHeading icon="phone">{deviceType} Setup Complete</PageHeading>
      <div className="mt-8 bg-white rounded-2xl border border-slate-200 p-6">
        <DoneScreenContent
          childName={childName}
          modelName={modelName}
          iosVersion={iosVersion}
        />
      </div>
    </div>
  );
};

const DoneScreenContent: React.FC<{
  childName: string;
  modelName: string;
  iosVersion: string;
}> = ({ childName, modelName, iosVersion }) => (
  <div>
    <div className="flex items-start gap-4 mb-6">
      <div className="w-14 h-14 rounded-xl bg-violet-100 flex items-center justify-center flex-shrink-0">
        <i className="fa-solid fa-check text-violet-600 text-2xl" />
      </div>
      <div className="flex-1">
        <div className="flex items-center justify-between mb-1">
          <p className="text-sm font-medium text-violet-600">Step 3 of 3</p>
          <ProgressDots current={3} total={3} />
        </div>
        <h1 className="text-xl font-bold text-slate-800">Setup Complete</h1>
        <p className="text-slate-500 text-sm mt-1">
          {childName}'s {modelName} · iOS {iosVersion}
        </p>
      </div>
    </div>

    <div className="bg-slate-50/50 rounded-2xl border border-slate-200 p-5 mb-6">
      <p className="text-slate-600 text-sm">
        {childName}'s {modelName} is now set up with Gertrude. You can manage this device
        from your dashboard.
      </p>
    </div>

    <div className="flex justify-end">
      <Button type="link" to="/ios-devices/mock-device-id" color="primary">
        Manage Device
      </Button>
    </div>
  </div>
);

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
