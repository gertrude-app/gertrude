import { Button } from '@gertrude/ui';
import { createFileRoute, redirect, useNavigate } from '@tanstack/react-router';
import React from 'react';
import Turnstile from 'react-turnstile';
import SignupPage from '#/components/pages/unauthed/SignupPage';
import { postAuthLocation, validateAuthRedirectSearch } from '#/lib/authRedirect';
import { isAuthed, setAuth } from '#/pairql/auth';
import { liveClient } from '#/pairql/client';

const SignupRoute: React.FC = () => {
  const { redirect: authRedirect } = Route.useSearch();
  const navigate = useNavigate();
  const [email, setEmail] = React.useState(``);
  const [password, setPassword] = React.useState(``);
  const [turnstileToken, setTurnstileToken] = React.useState<string>();
  const [submitting, setSubmitting] = React.useState(false);
  const [error, setError] = React.useState<string>();
  const [sent, setSent] = React.useState(false);
  const loginHref = authRedirect
    ? `/login?redirect=${encodeURIComponent(authRedirect)}`
    : `/login`;

  const handleSubmit = async (event: React.FormEvent): Promise<void> => {
    event.preventDefault();
    if (!email || !password || submitting) return;
    setSubmitting(true);
    setError(undefined);
    const result = await liveClient.accountSignup({
      email,
      password,
      redirect: authRedirect,
      turnstileToken,
    });
    setSubmitting(false);
    result.with({
      success: ({ accountId, token }) => {
        if (accountId && token) {
          setAuth(accountId, token);
          void navigate(postAuthLocation(authRedirect));
        } else {
          setSent(true);
        }
      },
      error: (err) => setError(err.userMessage ?? `Couldn't create your account.`),
    });
  };

  if (sent) {
    return (
      <main className="flex min-h-screen flex-col items-center justify-center gap-4 bg-stone-50 px-6 text-center">
        <h1 className="text-xl font-semibold text-stone-950">Check your email</h1>
        <p className="max-w-sm text-sm text-stone-600">
          We sent a verification link to {email}. Open it to finish creating your account
          and continue connecting your device.
        </p>
        <Button type="button" onClick={() => window.location.assign(loginHref)}>
          Log in instead
        </Button>
      </main>
    );
  }

  return (
    <>
      <SignupPage
        email={email}
        setEmail={setEmail}
        password={password}
        setPassword={setPassword}
        testimonials={[]}
        onSubmit={handleSubmit}
        loginHref={loginHref}
        submitting={submitting}
        turnstile={
          import.meta.env.VITE_TURNSTILE_SITEKEY ? (
            <Turnstile
              key="turnstile"
              sitekey={import.meta.env.VITE_TURNSTILE_SITEKEY}
              size="invisible"
              refreshExpired="auto"
              onVerify={setTurnstileToken}
              onExpire={() => setTurnstileToken(undefined)}
            />
          ) : undefined
        }
      />
      {error && (
        <p
          role="alert"
          className="fixed bottom-4 left-4 right-4 rounded-lg bg-red-50 p-4 text-center text-sm text-red-800 shadow-lg"
        >
          {error}
        </p>
      )}
    </>
  );
};

export const Route = createFileRoute(`/(unauthed)/signup`)({
  validateSearch: validateAuthRedirectSearch,
  beforeLoad: ({ search }) => {
    if (isAuthed()) throw redirect(postAuthLocation(search.redirect));
  },
  component: SignupRoute,
});
