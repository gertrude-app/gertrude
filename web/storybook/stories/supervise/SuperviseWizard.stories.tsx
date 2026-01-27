import {
  ChooseDirection,
  CodeEntry,
  Complete,
  ConfirmReboot,
  DeviceMismatch,
  DisableFindMy,
  DisablePrivateRelay,
  InProgress,
  PersonalizedConnect,
} from '@supervise/ui';
import type { Meta, StoryObj } from '@storybook/react';
import type { DeviceInfo } from '@supervise/ui';
import { appWindow } from '../story-helpers';

const mockDevice: DeviceInfo = {
  id: `00008030-001A34E22EFA802E`,
  name: `Jane's iPhone`,
  model: `iPhone 14 Pro`,
  osVersion: `17.2`,
};

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

export const Frame_ChooseDirection: Story = {
  render: () => (
    <Window>
      <ChooseDirection
        device={mockDevice}
        onChooseAdd={() => {}}
        onChooseRemove={() => {}}
      />
    </Window>
  ),
};

export const Frame_DisableFindMy: Story = {
  render: () => (
    <Window>
      <DisableFindMy onContinue={() => {}} />
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

export const Frame_InProgress_Ready: Story = {
  render: () => (
    <Window>
      <InProgress
        mode="add"
        deviceName={mockDevice.name}
        running={false}
        progress={0}
        onStart={() => {}}
      />
    </Window>
  ),
};

export const Frame_InProgress_Running: Story = {
  render: () => (
    <Window>
      <InProgress
        mode="add"
        deviceName={mockDevice.name}
        running={true}
        progress={45}
        onStart={() => {}}
      />
    </Window>
  ),
};

export const Frame_InProgress_Remove: Story = {
  render: () => (
    <Window>
      <InProgress
        mode="remove"
        deviceName={mockDevice.name}
        running={false}
        progress={0}
        onStart={() => {}}
      />
    </Window>
  ),
};

export const Frame_ConfirmReboot: Story = {
  render: () => (
    <Window>
      <ConfirmReboot onConfirm={() => {}} />
    </Window>
  ),
};

export const Frame_Complete_Add: Story = {
  render: () => (
    <Window>
      <Complete mode="add" deviceName={mockDevice.name} onDone={() => {}} />
    </Window>
  ),
};

export const Frame_Complete_Remove: Story = {
  render: () => (
    <Window>
      <Complete mode="remove" deviceName={mockDevice.name} onDone={() => {}} />
    </Window>
  ),
};

export default meta;
