import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import React from 'react';
import LoginPage from './LoginPage';
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

export const Signup = {
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <SignupStory />
    </StoryScreen>
  ),
};
