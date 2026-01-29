import {
  CodeEntry,
  Complete,
  ConfirmDevice,
  ConfirmSupervision,
  DeviceMismatch,
  DisableFindMy,
  DisablePrivateRelay,
  Error,
  GetReady,
  PersonalizedConnect,
  Supervising,
  SwipeToUpgrade,
} from '@supervise/ui';
import type { Meta, StoryObj } from '@storybook/react';
import { appWindow } from '../story-helpers';

const Window: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <div className="w-[900px] h-[700px] overflow-hidden bg-white rounded-lg shadow-lg">
    {children}
  </div>
);

const meta = {
  title: 'Supervise/Frames', // eslint-disable-line
  ...appWindow(900, 700),
} satisfies Meta;

type Story = StoryObj<typeof meta>;

export const CodeEntry_Empty: Story = {
  render: () => (
    <Window>
      <CodeEntry
        code=""
        onCodeChange={() => {}}
        onSubmit={() => {}}
        loading={false}
        error={null}
      />
    </Window>
  ),
};

export const CodeEntry_Full: Story = {
  render: () => (
    <Window>
      <CodeEntry
        code="123456"
        onCodeChange={() => {}}
        onSubmit={() => {}}
        loading={false}
        error={null}
      />
    </Window>
  ),
};

export const CodeEntry_Loading: Story = {
  render: () => (
    <Window>
      <CodeEntry
        code="123456"
        onCodeChange={() => {}}
        onSubmit={() => {}}
        loading={true}
        error={null}
      />
    </Window>
  ),
};

export const CodeEntry_Error: Story = {
  render: () => (
    <Window>
      <CodeEntry
        code="999999"
        onCodeChange={() => {}}
        onSubmit={() => {}}
        loading={false}
        error="Code not found. Check and try again."
      />
    </Window>
  ),
};

export const PersonalizedConnect_Default: Story = {
  render: () => (
    <Window>
      <PersonalizedConnect
        childName="Luke"
        deviceType="iPhone"
        modelName="iPhone 14"
        iosVersion="18.2"
      />
    </Window>
  ),
};

export const DeviceMismatch_Default: Story = {
  render: () => (
    <Window>
      <DeviceMismatch
        expectedModelName="iPhone 14"
        connectedModelName="iPhone 13"
        childName="Luke"
        onTryAgain={() => {}}
      />
    </Window>
  ),
};

export const Frame_ConfirmDevice: Story = {
  render: () => (
    <Window>
      <ConfirmDevice
        deviceName="Harriet's iPhone"
        iosVersion="18.5"
        onConfirm={() => {}}
        onReject={() => {}}
      />
    </Window>
  ),
};

export const Frame_DisableFindMy: Story = {
  render: () => (
    <Window>
      <DisableFindMy childName="Luke" deviceType="iPhone" onContinue={() => {}} />
    </Window>
  ),
};

export const Frame_DisablePrivateRelay: Story = {
  render: () => (
    <Window>
      <DisablePrivateRelay onContinue={() => {}} />
    </Window>
  ),
};

export const Frame_GetReady: Story = {
  render: () => (
    <Window>
      <GetReady onStart={() => {}} />
    </Window>
  ),
};

export const Frame_Supervising: Story = {
  render: () => (
    <Window>
      <Supervising />
    </Window>
  ),
};

export const Frame_SwipeToUpgrade: Story = {
  render: () => (
    <Window>
      <SwipeToUpgrade onContinue={() => {}} />
    </Window>
  ),
};

export const Frame_ConfirmSupervision: Story = {
  render: () => (
    <Window>
      <ConfirmSupervision onYes={() => {}} onNo={() => {}} />
    </Window>
  ),
};

export const Frame_Complete: Story = {
  render: () => (
    <Window>
      <Complete childName="Jane" deviceType="iPhone" onDone={() => {}} />
    </Window>
  ),
};

export const Frame_Error_FindMyEnabled: Story = {
  render: () => (
    <Window>
      <Error errorType="findMyEnabled" onRetry={() => {}} onContactSupport={() => {}} />
    </Window>
  ),
};

export const Frame_Error_InvokeFailed: Story = {
  render: () => (
    <Window>
      <Error
        errorType="invokeFailed"
        errorMessage="Device disconnected unexpectedly"
        onRetry={() => {}}
        onContactSupport={() => {}}
      />
    </Window>
  ),
};

export const Frame_Error_UserReportedNo: Story = {
  render: () => (
    <Window>
      <Error errorType="userReportedNo" onRetry={() => {}} onContactSupport={() => {}} />
    </Window>
  ),
};

export default meta;
