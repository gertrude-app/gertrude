import { SuperviseWizard } from '@supervise/ui';
import type { Meta, StoryObj } from '@storybook/react';
import type { DeviceInfo, SuperviseApi } from '@supervise/ui';
import { appWindow } from '../story-helpers';

const mockDevice: DeviceInfo = {
  id: `00008030-001A34E22EFA802E`,
  name: `Jane's iPhone`,
  model: `iPhone 14 Pro`,
  osVersion: `17.2`,
};

const mockApi: SuperviseApi = {
  getConnectedDevice: async () => {
    await new Promise((r) => setTimeout(r, 800));
    return mockDevice;
  },
  performOperation: async () => {
    await new Promise((r) => setTimeout(r, 3000));
  },
  closeWindow: () => {
    alert(`Window closed`);
  },
};

const noDeviceApi: SuperviseApi = {
  ...mockApi,
  getConnectedDevice: async () => {
    await new Promise((r) => setTimeout(r, 800));
    throw new Error(`No device connected. Please connect your iPhone via USB.`);
  },
};

const findMyEnabledApi: SuperviseApi = {
  ...mockApi,
  performOperation: async () => {
    await new Promise((r) => setTimeout(r, 1500));
    throw new Error(`Find My iPhone is enabled. Please disable it first.`);
  },
};

const meta = {
  title: 'Supervise/SuperviseWizard', // eslint-disable-line
  component: SuperviseWizard,
  ...appWindow(400, 350),
} satisfies Meta<typeof SuperviseWizard>;

type Story = StoryObj<typeof meta>;

export const Frame1_ConnectDevice: Story = {
  args: {
    api: mockApi,
    initialFrame: `connect-device`,
  },
};

export const Frame1_NoDeviceError: Story = {
  args: {
    api: noDeviceApi,
    initialFrame: `connect-device`,
    initialError: `No device connected. Please connect your iPhone via USB.`,
  },
};

export const Frame2_ChooseDirection: Story = {
  args: {
    api: mockApi,
    initialFrame: `choose-direction`,
    initialDevice: mockDevice,
  },
};

export const Frame3_DisableFindMy: Story = {
  args: {
    api: mockApi,
    initialFrame: `disable-find-my`,
    initialDevice: mockDevice,
  },
};

export const Frame4_DisablePrivateRelay: Story = {
  args: {
    api: mockApi,
    initialFrame: `disable-private-relay`,
    initialDevice: mockDevice,
  },
};

export const Frame5_InProgress_Add: Story = {
  args: {
    api: mockApi,
    initialFrame: `in-progress`,
    initialDevice: mockDevice,
    initialMode: `add`,
  },
};

export const Frame5_InProgress_Remove: Story = {
  args: {
    api: mockApi,
    initialFrame: `in-progress`,
    initialDevice: mockDevice,
    initialMode: `remove`,
  },
};

export const Frame5_FindMyError: Story = {
  args: {
    api: findMyEnabledApi,
    initialFrame: `in-progress`,
    initialDevice: mockDevice,
    initialMode: `add`,
    initialError: `Find My iPhone is enabled. Please disable it first.`,
  },
};

export const Frame6_ConfirmReboot: Story = {
  args: {
    api: mockApi,
    initialFrame: `confirm-reboot`,
    initialDevice: mockDevice,
  },
};

export const Frame7_Complete_Add: Story = {
  args: {
    api: mockApi,
    initialFrame: `complete`,
    initialDevice: mockDevice,
    initialMode: `add`,
  },
};

export const Frame7_Complete_Remove: Story = {
  args: {
    api: mockApi,
    initialFrame: `complete`,
    initialDevice: mockDevice,
    initialMode: `remove`,
  },
};

export default meta;
