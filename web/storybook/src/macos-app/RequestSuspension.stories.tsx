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
    customDurationString: ``,
    emit: () => {},
    dispatch: () => {},
  },
});

export const FilledOutLight: Story = props({
  ...LightMode.args,
  props: {
    ...LightMode.args.props,
    comment: `Please dad!`,
    durationInSeconds: 60 * 120,
  },
});

export const MainOverlayLight: Story = props({
  ...LightMode.args,
  props: {
    ...LightMode.args.props,
    overlay: `main`,
  },
});

export const CustomOverlayLight: Story = props({
  ...LightMode.args,
  props: {
    ...LightMode.args.props,
    overlay: `customDuration`,
  },
});

export const CustomOverlayFilledOutLight: Story = props({
  ...LightMode.args,
  props: {
    ...LightMode.args.props,
    overlay: `customDuration`,
    customDurationString: `113`,
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

export const FilledOutDark: Story = props({
  ...DarkMode.args,
  props: {
    ...DarkMode.args.props,
    comment: `Please dad!`,
    durationInSeconds: 60 * 9,
  },
});

export const MainOverlayDark: Story = props({
  ...DarkMode.args,
  props: {
    ...DarkMode.args.props,
    overlay: `main`,
  },
});

export const CustomOverlayDark: Story = props({
  ...DarkMode.args,
  props: {
    ...DarkMode.args.props,
    overlay: `customDuration`,
  },
});

export const CustomOverlayFilledOutDark: Story = props({
  ...DarkMode.args,
  props: {
    ...DarkMode.args.props,
    overlay: `customDuration`,
    customDurationString: `113`,
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

export const AccountInactiveDark: Story = props({
  ...DarkMode.args,
  props: {
    ...DarkMode.args.props,
    adminAccountStatus: `inactive`,
  },
});

export default meta;
