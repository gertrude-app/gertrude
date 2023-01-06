import { RequestModal } from '@dash/components';
import type { ComponentStory, ComponentMeta } from '@storybook/react';

export default {
  title: 'Dashboard/Modal/RequestModal', // eslint-disable-line
  component: RequestModal,
} as ComponentMeta<typeof RequestModal>;

const Template: ComponentStory<typeof RequestModal> = (args) => (
  <RequestModal {...args} />
);

export const Loading = Template.bind({});
Loading.args = {
  request: { state: `ongoing` },
  successTitle: `Success`,
  withPayload: (payload) => <h1>Got your payload here: {JSON.stringify(payload)}</h1>,
  primaryButton: () => {},
};

export const Loaded = Template.bind({});
Loaded.args = {
  ...Loading.args,
  request: { state: `succeeded`, payload: `123` },
};

export const Error = Template.bind({});
Error.args = {
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
};
