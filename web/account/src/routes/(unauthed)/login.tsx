import { toast } from '@gertrude/ui';
import { createFileRoute, redirect, useNavigate } from '@tanstack/react-router';
import React from 'react';
import LoginPage from '#/components/pages/unauthed/LoginPage';
import { isAuthed, setAuth } from '#/pairql/auth';
import { liveClient } from '#/pairql/client';

const LoginRoute: React.FC = () => {
  const navigate = useNavigate();
  const [email, setEmail] = React.useState(``);
  const [password, setPassword] = React.useState(``);
  const [submitting, setSubmitting] = React.useState(false);
  const [sendingLink, setSendingLink] = React.useState(false);

  async function handleSubmit(event: React.FormEvent): Promise<void> {
    event.preventDefault();
    if (!email || !password || submitting) return;
    setSubmitting(true);
    const result = await liveClient.accountLogin({ email, password });
    setSubmitting(false);
    result.with({
      success: ({ accountId, token }) => {
        setAuth(accountId, token);
        void navigate({ to: `/people` });
      },
      error: (err) => {
        toast.error(err.userMessage ?? `Login failed — check your email and password.`);
      },
    });
  }

  async function handleMagicLink(): Promise<void> {
    if (!email || sendingLink) return;
    setSendingLink(true);
    const result = await liveClient.accountRequestMagicLink({ email });
    setSendingLink(false);
    result.with({
      success: () => toast.success(`Check your email for a sign-in link.`),
      error: (err) => toast.error(err.userMessage ?? `Couldn't send the magic link.`),
    });
  }

  return (
    <LoginPage
      email={email}
      setEmail={setEmail}
      password={password}
      setPassword={setPassword}
      submitting={submitting}
      sendingLink={sendingLink}
      onSubmit={handleSubmit}
      onMagicLink={handleMagicLink}
    />
  );
};

export const Route = createFileRoute(`/(unauthed)/login`)({
  beforeLoad: () => {
    if (isAuthed()) {
      throw redirect({ to: `/people` });
    }
  },
  component: LoginRoute,
});
