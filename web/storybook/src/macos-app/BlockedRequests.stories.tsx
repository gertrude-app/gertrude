import { BlockedRequests } from '@macos/appviews';
import type { Meta, StoryObj } from '@storybook/react';
import type { ComponentProps as Wrapping } from 'react';
import { withIdsAnd } from '../story-helpers';
import { props } from '../story-helpers';
import AppWindow from './AppWindow';

const meta = {
  title: 'MacOS App/Blocked Requests', // eslint-disable-line
  component: AppWindow<Wrapping<typeof BlockedRequests>>,
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof AppWindow<Wrapping<typeof BlockedRequests>>>;

type Story = StoryObj<typeof meta>;

export const LightMode = props({
  width: 900,
  height: 600,
  wrapping: BlockedRequests,
  fullscreen: true,
  props: {
    requests: requests(),
    windowOpen: true,
    filterText: ``,
    tcpOnly: false,
    createUnlockRequests: { case: `idle` },
    selectedRequestIds: [],
    unlockRequestExplanation: ``,
    emit: () => {},
    dispatch: () => {},
  },
});

export const LightModeSelected = props({
  ...LightMode.args,
  props: {
    ...LightMode.args.props,
    unlockRequestExplanation: `need this for my math class, dad!`,
    selectedRequestIds: [`1`, `2`],
  },
});

export const LightModeEmpty = props({
  ...LightMode.args,
  props: {
    ...LightMode.args.props,
    requests: [],
  },
});

export const LightModeFilteredEmpty = props({
  ...LightMode.args,
  props: {
    ...LightMode.args.props,
    filterText: `kieth hejinal`,
  },
});

export const LightModeSubmitting = props({
  ...LightModeSelected.args,
  props: {
    ...LightModeSelected.args.props,
    createUnlockRequests: { case: `ongoing` },
  },
});

export const LightModeSubmitSuccess = props({
  ...LightModeSelected.args,
  props: {
    ...LightModeSelected.args.props,
    createUnlockRequests: { case: `succeeded` },
  },
});

export const LightModeSubmitError = props({
  ...LightModeSelected.args,
  props: {
    ...LightModeSelected.args.props,
    createUnlockRequests: { case: `failed`, error: `Something went wrong` },
  },
});

export const DarkMode = props({
  ...LightMode.args,
  dark: true,
});

export const DarkModeSelected = props({
  ...LightMode.args,
  dark: true,
  props: {
    ...LightMode.args.props,
    selectedRequestIds: [`1`, `2`],
  },
});

export const DarkModeEmpty = props({
  ...DarkMode.args,
  props: {
    ...DarkMode.args.props,
    requests: [],
  },
});

export const DarkModeFilteredEmpty = props({
  ...DarkMode.args,
  props: {
    ...DarkMode.args.props,
    filterText: `kieth hejinal`,
  },
});

export const DarkModeSubmitting = props({
  ...LightModeSelected.args,
  dark: true,
  props: {
    ...LightModeSelected.args.props,
    createUnlockRequests: { case: `loading` },
  },
});

export const DarkModeSubmitSuccess = props({
  ...LightModeSelected.args,
  dark: true,
  props: {
    ...LightModeSelected.args.props,
    createUnlockRequests: { case: `succeeded` },
  },
});

export const DarkModeSubmitError = props({
  ...LightModeSelected.args,
  dark: true,
  props: {
    ...LightModeSelected.args.props,
    createUnlockRequests: { case: `failed`, error: `something went wrong` },
  },
});

// helpers

function requests(): Array<Story['args']['props']['requests'][number]> {
  return withIdsAnd({ searchableText: `` }, [
    {
      time: `2023-04-20T19:29:59.262Z`,
      protocol: `tcp` as const,
      target: `google.com`,
      app: `Firefox Browser`,
    },
    {
      time: `2023-04-20T19:29:59.262Z`,
      protocol: `tcp` as const,
      target: `guzzoni.apple.com`,
      app: `.com.apple.assistantd`,
    },
    {
      time: `2023-04-20T19:29:59.262Z`,
      protocol: `tcp` as const,
      target: `khanacademy.com`,
      app: `Firefox Browser`,
    },
    {
      time: `2023-04-20T19:29:59.262Z`,
      protocol: `udp` as const,
      target: `172.64.80.1`,
      app: `Firefox Browser`,
    },
    {
      time: `2023-04-20T19:29:59.262Z`,
      protocol: `tcp` as const,
      target: `https://bag.itunes.apple.com/bag.xml?deviceClass=Macintosh&format=json`,
      app: `.com.apple.appstoreagent`,
    },
    {
      time: `2023-04-20T19:29:59.262Z`,
      protocol: `tcp` as const,
      target: `outlook.office365.com/foo/barbaz`,
      app: `Firefox Browser`,
    },
    {
      time: `2023-04-20T19:29:59.262Z`,
      protocol: `udp` as const,
      target: `172.64.80.1`,
      app: `Firefox Browser`,
    },
    {
      time: `2023-04-20T19:29:59.262Z`,
      protocol: `tcp` as const,
      target: `google.com`,
      app: `Firefox Browser`,
    },
    {
      time: `2023-04-20T19:29:59.262Z`,
      protocol: `tcp` as const,
      target: `guzzoni.apple.com`,
      app: `.com.apple.assistantd`,
    },
    {
      time: `2023-04-20T19:29:59.262Z`,
      protocol: `tcp` as const,
      target: `khanacademy.com`,
      app: `Firefox Browser`,
    },
    {
      time: `2023-04-20T19:29:59.262Z`,
      protocol: `udp` as const,
      target: `172.64.80.1`,
      app: `Firefox Browser`,
    },
    {
      time: `2023-04-20T19:29:59.262Z`,
      protocol: `tcp` as const,
      target: `https://bag.itunes.apple.com/bag.xml?deviceClass=Macintosh&format=json`,
      app: `.com.apple.appstoreagent`,
    },
    {
      time: `2023-04-20T19:29:59.262Z`,
      protocol: `tcp` as const,
      target: `outlook.office365.com/foo/barbaz`,
      app: `Firefox Browser`,
    },
    {
      time: `2023-04-22T21:00:01.262Z`,
      protocol: `udp` as const,
      target: `123.45.67.89`,
      app: `Firefox Browser`,
    },
  ]);
}

export default meta;
