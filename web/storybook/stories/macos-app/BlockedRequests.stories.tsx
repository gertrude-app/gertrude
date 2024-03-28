import { BlockedRequests } from '@macos/appviews';
import type { Meta, StoryObj } from '@storybook/react';
import { withIdsAnd } from '../story-helpers';
import { props, appWindow } from '../story-helpers';

const meta = {
  title: 'MacOS App/Blocked Requests', // eslint-disable-line
  component: BlockedRequests,
  parameters: appWindow(),
} satisfies Meta<typeof BlockedRequests>;

type Story = StoryObj<typeof meta>;

export const Default = props({
  adminAccountStatus: `active` as const,
  requests: requests(),
  windowOpen: true,
  filterText: ``,
  tcpOnly: false,
  createUnlockRequests: { case: `idle` } as const,
  selectedRequestIds: [],
  unlockRequestExplanation: ``,
  filterCommunicationConfirmed: undefined,
  emit: () => {},
  dispatch: () => {},
});

export const Wide = props({
  ...Default.args,
  width: 1200,
});

export const NoFilterCommunication = props({
  ...Default.args,
  filterCommunicationConfirmed: false,
});

export const Selected = props({
  ...Default.args,
  unlockRequestExplanation: `need this for my math class, dad!`,
  selectedRequestIds: [`12`, `13`],
});

export const Empty = props({
  ...Default.args,
  requests: [],
});

export const FilteredEmpty = props({
  ...Default.args,
  filterText: `kieth hejinal`,
});

export const Submitting = props({
  ...Selected.args,
  createUnlockRequests: { case: `ongoing` },
});

export const SubmitSuccess = props({
  ...Selected.args,
  createUnlockRequests: { case: `succeeded` },
});

export const SubmitError = props({
  ...Selected.args,
  createUnlockRequests: { case: `failed`, error: `Something went wrong` },
});

export const AccountNeedsAttention = props({
  ...Selected.args,
  adminAccountStatus: `needsAttention`,
});

export const AccountInactive = props({
  ...Selected.args,
  adminAccountStatus: `inactive`,
});

// helpers

function requests(): Array<Story['args']['requests'][number]> {
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
