import { RequestSuspension } from '@macos/appviews';
import type { Meta, StoryObj } from '@storybook/react';
import type { ComponentProps as Wrapping } from 'react';
import { props } from '../story-helpers';
import AppWindow from './AppWindow';

const meta = {
  title: 'MacOS App/RequestSuspension', // eslint-disable-line
  component: AppWindow<Wrapping<typeof RequestSuspension>>,
  parameters: { layout: `centered` },
} satisfies Meta<typeof AppWindow<Wrapping<typeof RequestSuspension>>>;

type Story = StoryObj<typeof meta>;

export const LightMode: Story = props({
  width: 600,
  height: 400,
  wrapping: RequestSuspension,
  props: {
    windowOpen: true,
    adminAccountStatus: `active` as const,
    request: { case: `idle` },
    comment: ``,
    page: `duration`,
    duration: { mode: `standard`, seconds: null },
    internetConnected: true,
    emit: () => {},
    dispatch: () => {},
  },
});

export const NoInternetLight: Story = props({
  ...LightMode.args,
  props: {
    ...LightMode.args.props,
    internetConnected: false,
  },
});

export const OptionSelectedLight: Story = props({
  ...LightMode.args,
  props: {
    ...LightMode.args.props,
    comment: `Please dad!`,
    duration: {
      mode: `standard`,
      seconds: 1800,
    },
  },
});

export const CustomDurationDrawerOpenLight: Story = props({
  ...LightMode.args,
  props: {
    ...LightMode.args.props,
    duration: {
      mode: `custom`,
      seconds: null,
    },
  },
});

export const CustomDurationDrawerFilledOutLight: Story = props({
  ...LightMode.args,
  props: {
    ...LightMode.args.props,
    duration: {
      mode: `custom`,
      seconds: 3660,
    },
  },
});

export const CommentPageLight: Story = props({
  ...LightMode.args,
  props: {
    ...LightMode.args.props,
    page: `comment`,
    duration: {
      mode: `standard`,
      seconds: 1800,
    },
  },
});

export const SubmittingLight: Story = props({
  ...LightMode.args,
  props: {
    ...LightMode.args.props,
    request: { case: `ongoing` },
  },
});

export const SubmittedLight: Story = props({
  ...LightMode.args,
  props: {
    ...LightMode.args.props,
    request: { case: `succeeded` },
  },
});

export const SubmitErrorLight: Story = props({
  ...LightMode.args,
  props: {
    ...LightMode.args.props,
    request: { case: `failed`, error: `Printer on fire` },
  },
});

export const AccountWarningLight: Story = props({
  ...LightMode.args,
  props: {
    ...LightMode.args.props,
    adminAccountStatus: `needsAttention`,
  },
});

export const AccountWarningDrawerOpenLight: Story = props({
  ...LightMode.args,
  props: {
    ...LightMode.args.props,
    adminAccountStatus: `needsAttention`,
    duration: {
      mode: `custom`,
      seconds: null,
    },
  },
});

export const AccountInactiveLight: Story = props({
  ...LightMode.args,
  props: {
    ...LightMode.args.props,
    adminAccountStatus: `inactive`,
  },
});

export const DarkMode: Story = props({
  ...LightMode.args,
  dark: true,
});

export const NoInternetDark: Story = props({
  ...DarkMode.args,
  props: {
    ...DarkMode.args.props,
    internetConnected: false,
  },
});

export const OptionSelectedDark: Story = props({
  ...DarkMode.args,
  props: {
    ...DarkMode.args.props,
    comment: `Please dad!`,
    duration: {
      mode: `standard`,
      seconds: 1800,
    },
  },
});

export const CustomDurationDrawerOpenDark: Story = props({
  ...DarkMode.args,
  props: {
    ...DarkMode.args.props,
    duration: {
      mode: `custom`,
      seconds: null,
    },
  },
});

export const CustomDurationDrawerFilledOutDark: Story = props({
  ...DarkMode.args,
  props: {
    ...DarkMode.args.props,
    duration: {
      mode: `custom`,
      seconds: 3660,
    },
  },
});

export const CommentPageDark: Story = props({
  ...DarkMode.args,
  props: {
    ...DarkMode.args.props,
    page: `comment`,
    duration: {
      mode: `standard`,
      seconds: 1800,
    },
  },
});

export const SubmittingDark: Story = props({
  ...DarkMode.args,
  props: {
    ...DarkMode.args.props,
    request: { case: `ongoing` },
  },
});

export const SubmittedDark: Story = props({
  ...DarkMode.args,
  props: {
    ...DarkMode.args.props,
    request: { case: `succeeded` },
  },
});

export const SubmitErrorDark: Story = props({
  ...DarkMode.args,
  props: {
    ...DarkMode.args.props,
    request: { case: `failed`, error: `Printer on fire` },
  },
});

export const AccountWarningDark: Story = props({
  ...DarkMode.args,
  props: {
    ...DarkMode.args.props,
    adminAccountStatus: `needsAttention`,
  },
});

export const AccountWarningDrawerOpenDark: Story = props({
  ...DarkMode.args,
  props: {
    ...DarkMode.args.props,
    adminAccountStatus: `needsAttention`,
    duration: {
      mode: `custom`,
      seconds: null,
    },
  },
});

export const AccountInactiveDark: Story = props({
  ...DarkMode.args,
  props: {
    ...DarkMode.args.props,
    adminAccountStatus: `inactive`,
  },
});

export default meta;
