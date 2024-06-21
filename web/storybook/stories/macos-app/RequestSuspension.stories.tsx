import { RequestSuspension } from '@macos/appviews';
import type { Meta, StoryObj } from '@storybook/react';
import { appWindow, props } from '../story-helpers';

const meta = {
  title: 'MacOS App/RequestSuspension', // eslint-disable-line
  component: RequestSuspension,
  parameters: appWindow(680, 360),
} satisfies Meta<typeof RequestSuspension>;

type Story = StoryObj<typeof meta>;

export const Default: Story = props({
  windowOpen: true,
  adminAccountStatus: `active` as const,
  request: { case: `idle` },
  comment: ``,
  page: `duration`,
  duration: { mode: `standard`, seconds: null },
  internetConnected: true,
  filterCommunicationConfirmed: true,
  emit: () => {},
  dispatch: () => {},
});

export const NoInternet: Story = props({
  ...Default.args,
  internetConnected: false,
});

export const NoFilterCommunication = props({
  ...Default.args,
  filterCommunicationConfirmed: false,
});

export const OptionSelected: Story = props({
  ...Default.args,
  comment: `Please dad!`,
  duration: {
    mode: `standard`,
    seconds: 1800,
  },
});

export const CustomDurationDrawerOpen: Story = props({
  ...Default.args,
  duration: {
    mode: `custom`,
    seconds: null,
  },
});

export const CustomDurationDrawerFilledOut: Story = props({
  ...Default.args,
  duration: {
    mode: `custom`,
    seconds: 3660,
  },
});

export const CommentPage: Story = props({
  ...Default.args,
  page: `comment`,
  duration: {
    mode: `standard`,
    seconds: 1800,
  },
});

export const Submitting: Story = props({
  ...Default.args,
  request: { case: `ongoing` },
});

export const Submitted: Story = props({
  ...Default.args,
  request: { case: `succeeded` },
});

export const SubmitError: Story = props({
  ...Default.args,
  request: { case: `failed`, error: `Printer on fire` },
});

export const AccountWarning: Story = props({
  ...Default.args,
  adminAccountStatus: `needsAttention`,
});

export const AccountWarningDrawerOpen: Story = props({
  ...Default.args,
  adminAccountStatus: `needsAttention`,
  duration: {
    mode: `custom`,
    seconds: null,
  },
});

export const AccountInactive: Story = props({
  ...Default.args,
  adminAccountStatus: `inactive`,
});

export default meta;
