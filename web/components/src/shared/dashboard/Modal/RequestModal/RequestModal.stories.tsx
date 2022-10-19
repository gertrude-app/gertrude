import { ComponentStory, ComponentMeta } from '@storybook/react';
import RequestModal from './RequestModal';

export default {
  title: `Dashboard/Core/Modal/RequestModal`,
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
  withError: (err) => <h1>Got your error here, type: {err?.type}</h1>,
  onPrimaryClick: () => {},
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
    error: { type: `actionable`, message: `Well shucks, we blew a gasket.` },
  },
};
