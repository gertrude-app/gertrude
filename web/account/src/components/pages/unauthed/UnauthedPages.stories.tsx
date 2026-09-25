import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import React from 'react';
import LoginPage from './LoginPage';
import { ChooseNewPasswordPage, RequestPasswordResetPage } from './PasswordResetPages';
import SignupPage from './SignupPage';
import VerifySignupEmailPage from './VerifySignupEmailPage';
import { testimonials } from '#/components/unauthed/testimonials';

const noop = (): void => {};
const preventSubmit = (event: React.FormEvent): void => event.preventDefault();

const meta = {
  title: 'Account/Pages/Unauthed',
  parameters: { layout: 'fullscreen', screenshotsAt: ['mobile', 'desktop'] },
};

export default meta;

const LoginStory: React.FC<{ error?: string }> = ({ error }) => {
  const [email, setEmail] = React.useState(`parent@example.com`);
  const [password, setPassword] = React.useState(``);

  return (
    <LoginPage
      email={email}
      setEmail={setEmail}
      password={password}
      setPassword={setPassword}
      error={error}
      onSubmit={preventSubmit}
      onMagicLink={noop}
    />
  );
};

const RequestPasswordResetStory: React.FC = () => {
  const [email, setEmail] = React.useState(`parent@example.com`);

  return (
    <RequestPasswordResetPage
      email={email}
      setEmail={setEmail}
      submitting={false}
      sent={false}
      backLink={{ text: `Back to login`, href: `/login` }}
      onSubmit={preventSubmit}
    />
  );
};

const ChooseNewPasswordStory: React.FC = () => {
  const [password, setPassword] = React.useState(``);

  return (
    <ChooseNewPasswordPage
      password={password}
      setPassword={setPassword}
      submitting={false}
      succeeded={false}
      invalidToken={false}
      backLink={{ text: `Back to login`, href: `/login` }}
      onSubmit={preventSubmit}
    />
  );
};

const SignupStory: React.FC<{ sent?: boolean; error?: string }> = ({ sent, error }) => {
  const [email, setEmail] = React.useState(sent ? `parent@example.com` : ``);
  const [password, setPassword] = React.useState(``);

  return (
    <SignupPage
      email={email}
      setEmail={setEmail}
      password={password}
      setPassword={setPassword}
      testimonials={testimonials}
      sent={sent}
      error={error}
      onSubmit={preventSubmit}
      onResend={noop}
      onChangeEmail={noop}
    />
  );
};

export const Login = {
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <LoginStory />
    </StoryScreen>
  ),
};

export const LoginError = {
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <LoginStory error="Incorrect email or password" />
    </StoryScreen>
  ),
};

export const RequestPasswordReset = {
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <RequestPasswordResetStory />
    </StoryScreen>
  ),
};

export const ChooseNewPassword = {
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <ChooseNewPasswordStory />
    </StoryScreen>
  ),
};

export const Signup = {
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <SignupStory />
    </StoryScreen>
  ),
};

export const SignupEmailSent = {
  render: () => (
    <StoryScreen>
      <SignupStory sent />
    </StoryScreen>
  ),
};

export const SignupError = {
  render: () => (
    <StoryScreen>
      <SignupStory error="Couldn't send your signup email. Please try again." />
    </StoryScreen>
  ),
};

export const VerificationExpired = {
  render: () => (
    <StoryScreen>
      <VerifySignupEmailPage
        state={{
          status: `error`,
          message: `The link you clicked has expired, but we sent a new verification email. Please check your email and try again.`,
          retryable: false,
        }}
        onRetry={noop}
      />
    </StoryScreen>
  ),
};

export const EmailAlreadyVerified = {
  render: () => (
    <StoryScreen>
      <VerifySignupEmailPage state={{ status: `alreadyVerified` }} onRetry={noop} />
    </StoryScreen>
  ),
};
