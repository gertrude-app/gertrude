import {
  DeviceContextBanner,
  EmailInputForm,
  FullscreenModalForm,
  LoginForm,
} from '@dash/components';
import type { Meta, StoryObj } from '@storybook/react';

const meta = {
  title: 'Dashboard/Unauthed/DeviceContextBanner', // eslint-disable-line
  component: DeviceContextBanner,
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof DeviceContextBanner>;

type Story = StoryObj<typeof DeviceContextBanner>;

export const SignupWithIPhone: Story = {
  render: () => (
    <FullscreenModalForm state="idle">
      <EmailInputForm
        id="signup"
        title="Signup"
        subTitle={
          <>
            Got an account?{` `}
            <span className="text-violet-700 border-b border-dotted border-violet-700">
              Login
            </span>
            {` `}
            instead.
          </>
        }
        beforeInputs={<DeviceContextBanner modelName="iPhone 14 Pro" iosVersion="18.2" />}
        email=""
        setEmail={() => {}}
        password=""
        setPassword={() => {}}
        onSubmit={() => {}}
      />
    </FullscreenModalForm>
  ),
};

export const SignupWithIPad: Story = {
  render: () => (
    <FullscreenModalForm state="idle">
      <EmailInputForm
        id="signup"
        title="Signup"
        subTitle={
          <>
            Got an account?{` `}
            <span className="text-violet-700 border-b border-dotted border-violet-700">
              Login
            </span>
            {` `}
            instead.
          </>
        }
        beforeInputs={
          <DeviceContextBanner modelName="iPad Pro 12.9-inch" iosVersion="18.1" />
        }
        email=""
        setEmail={() => {}}
        password=""
        setPassword={() => {}}
        onSubmit={() => {}}
      />
    </FullscreenModalForm>
  ),
};

export const LoginWithIPhone: Story = {
  render: () => (
    <FullscreenModalForm state="idle">
      <LoginForm
        email=""
        setEmail={() => {}}
        password=""
        setPassword={() => {}}
        onSubmit={() => {}}
        onSendMagicLink={() => {}}
        beforeInputs={
          <DeviceContextBanner
            modelName="iPhone 15"
            iosVersion="17.4"
            label="Login to supervise:"
          />
        }
      />
    </FullscreenModalForm>
  ),
};

export const SignupNoVersion: Story = {
  render: () => (
    <FullscreenModalForm state="idle">
      <EmailInputForm
        id="signup"
        title="Signup"
        subTitle={
          <>
            Got an account?{` `}
            <span className="text-violet-700 border-b border-dotted border-violet-700">
              Login
            </span>
            {` `}
            instead.
          </>
        }
        beforeInputs={<DeviceContextBanner modelName="iPhone SE (3rd generation)" />}
        email=""
        setEmail={() => {}}
        password=""
        setPassword={() => {}}
        onSubmit={() => {}}
      />
    </FullscreenModalForm>
  ),
};

export default meta;
