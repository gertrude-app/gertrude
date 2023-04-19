import { RequestModal } from '@dash/components';
import type { StoryObj, Meta } from '@storybook/react';
import { props } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Modal/RequestModal', // eslint-disable-line
  component: RequestModal,
} satisfies Meta<typeof RequestModal>;

type Story = StoryObj<typeof meta>;

export const Loading: Story = props({
  request: { state: `ongoing` },
  successTitle: `Success`,
  withPayload: (payload) => <h1>Got your payload here: {JSON.stringify(payload)}</h1>,
  primaryButton: () => {},
});

export const Loaded: Story = props({
  ...Loading.args,
  request: { state: `succeeded`, payload: `123` },
});

export const Error: Story = props({
  ...Loading.args,
  request: {
    state: `failed`,
    error: {
      id: ``,
      type: `clientError`,
      debugMessage: ``,
      userMessage: `Well shucks, we blew a gasket.`,
    },
  },
});

export default meta;
