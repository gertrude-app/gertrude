import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import React from 'react';
import LoginPage from './LoginPage';
import { ChooseNewPasswordPage, RequestPasswordResetPage } from './PasswordResetPages';
import SignupPage from './SignupPage';
import { testimonials } from '#/components/storybook/fixtures';

const noop = (): void => {};
const preventSubmit = (event: React.FormEvent): void => event.preventDefault();

const meta = {
  title: 'Account/Pages/Unauthed',
  parameters: { layout: 'fullscreen', screenshotsAt: ['mobile', 'desktop'] },
};

export default meta;

const LoginStory: React.FC = () => {
  const [email, setEmail] = React.useState(`parent@example.com`);
  const [password, setPassword] = React.useState(``);

  return (
    <LoginPage
      email={email}
      setEmail={setEmail}
      password={password}
      setPassword={setPassword}
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

const SignupStory: React.FC = () => {
  const [email, setEmail] = React.useState(``);
  const [password, setPassword] = React.useState(``);

  return (
    <SignupPage
      email={email}
      setEmail={setEmail}
      password={password}
      setPassword={setPassword}
      testimonials={testimonials}
      onSubmit={preventSubmit}
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
