import { toast } from '@gertrude/ui';
import { createFileRoute, redirect, useNavigate } from '@tanstack/react-router';
import React from 'react';
import LoginPage from '#/components/pages/unauthed/LoginPage';
import { postAuthLocation, validateAuthRedirectSearch } from '#/lib/authRedirect';
import { isAuthed, setAuth } from '#/pairql/auth';
import { liveClient } from '#/pairql/client';

const LoginRoute: React.FC = () => {
  const navigate = useNavigate();
  const { redirect: authRedirect } = Route.useSearch();
  const [email, setEmail] = React.useState(``);
  const [password, setPassword] = React.useState(``);
  const [submitting, setSubmitting] = React.useState(false);
  const [sendingLink, setSendingLink] = React.useState(false);
  const [error, setError] = React.useState<string | null>(null);

  function handleEmailChange(value: string): void {
    setEmail(value);
    setError(null);
  }

  function handlePasswordChange(value: string): void {
    setPassword(value);
    setError(null);
  }

  async function handleSubmit(event: React.FormEvent): Promise<void> {
    event.preventDefault();
    if (!email || !password || submitting) return;
    setError(null);
    setSubmitting(true);
    const result = await liveClient.accountLogin({ email, password });
    setSubmitting(false);
    result.with({
      success: ({ accountId, token }) => {
        setAuth(accountId, token);
        void navigate(postAuthLocation(authRedirect));
      },
      error: (err) => {
        setError(err.userMessage ?? `Couldn't log in. Please try again.`);
      },
    });
  }

  async function handleMagicLink(): Promise<void> {
    if (!email || sendingLink) return;
    setError(null);
    setSendingLink(true);
    const result = await liveClient.accountRequestMagicLink({
      email,
      redirect: authRedirect,
    });
    setSendingLink(false);
    result.with({
      success: () => toast.success(`Check your email for a sign-in link.`),
      error: (err) =>
        setError(err.userMessage ?? `Couldn't send the magic link. Please try again.`),
    });
  }

  return (
    <LoginPage
      email={email}
      setEmail={handleEmailChange}
      password={password}
      setPassword={handlePasswordChange}
      error={error}
      submitting={submitting}
      sendingLink={sendingLink}
      onSubmit={handleSubmit}
      onMagicLink={handleMagicLink}
    />
  );
};

export const Route = createFileRoute(`/(unauthed)/login`)({
  validateSearch: validateAuthRedirectSearch,
  beforeLoad: ({ search }) => {
    if (isAuthed()) {
      throw redirect(postAuthLocation(search.redirect));
    }
  },
  component: LoginRoute,
});
