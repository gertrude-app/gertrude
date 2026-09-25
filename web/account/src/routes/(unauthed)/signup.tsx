import { Button, Text, VStack } from '@gertrude/ui';
import { Turnstile } from '@marsidev/react-turnstile';
import { createFileRoute, redirect, useNavigate } from '@tanstack/react-router';
import React from 'react';
import SignupPage from '#/components/pages/unauthed/SignupPage';
import { testimonials } from '#/components/unauthed/testimonials';
import { signupAttribution } from '#/lib/signup';
import { isAuthed, setAuth } from '#/pairql/auth';
import { liveClient } from '#/pairql/client';

const sitekey = import.meta.env.DEV ? undefined : import.meta.env.VITE_TURNSTILE_SITEKEY;
const missingSecurityConfig = !sitekey && !import.meta.env.DEV;

const SignupRoute: React.FC = () => {
  const navigate = useNavigate();
  const [email, setEmail] = React.useState(``);
  const [password, setPassword] = React.useState(``);
  const [submitting, setSubmitting] = React.useState(false);
  const [sent, setSent] = React.useState(false);
  const [error, setError] = React.useState<string | null>(null);
  const [resendSeconds, setResendSeconds] = React.useState(0);
  const [turnstileToken, setTurnstileToken] = React.useState<string | null>(null);
  const [challengeVersion, setChallengeVersion] = React.useState(0);
  const [challengeFailed, setChallengeFailed] = React.useState(false);
  const [attribution] = React.useState(() =>
    signupAttribution(window.location.search, document.cookie),
  );
  const securityReady = !missingSecurityConfig && (!sitekey || turnstileToken !== null);

  React.useEffect(() => {
    if (resendSeconds === 0) return;
    const timer = window.setTimeout(
      () => setResendSeconds((seconds) => seconds - 1),
      1000,
    );
    return () => window.clearTimeout(timer);
  }, [resendSeconds]);

  function handleChallengeFailure(): void {
    setTurnstileToken(null);
    setChallengeFailed(true);
  }

  function resetChallenge(): void {
    if (!window.turnstile) document.getElementById(`account-signup-turnstile`)?.remove();
    setTurnstileToken(null);
    setChallengeFailed(false);
    setChallengeVersion((version) => version + 1);
  }

  async function signup(): Promise<void> {
    if (
      !email.trim() ||
      password.length < 5 ||
      submitting ||
      !securityReady ||
      (sent && resendSeconds > 0)
    )
      return;
    setError(null);
    setSubmitting(true);
    const result = await liveClient.accountSignup({
      email: email.trim(),
      password,
      ...attribution,
      turnstileToken: turnstileToken ?? undefined,
    });
    setSubmitting(false);
    resetChallenge();
    result.with({
      success: ({ account }) => {
        if (account) {
          setAuth(account.accountId, account.token);
          void navigate({ to: `/people`, replace: true });
        } else {
          setEmail(email.trim());
          setSent(true);
          setResendSeconds(60);
        }
      },
      error: (error) =>
        setError(
          error.userMessage ?? `Couldn't send your signup email. Please try again.`,
        ),
    });
  }

  return (
    <SignupPage
      email={email}
      setEmail={(value) => {
        setEmail(value);
        setError(null);
      }}
      password={password}
      setPassword={(value) => {
        setPassword(value);
        setError(null);
      }}
      testimonials={testimonials}
      submitting={submitting}
      sent={sent}
      error={
        missingSecurityConfig
          ? `Account creation is temporarily unavailable. Please try again later.`
          : error
      }
      resendSeconds={resendSeconds}
      securityReady={securityReady}
      onSubmit={(event) => {
        event.preventDefault();
        void signup();
      }}
      onResend={() => void signup()}
      onChangeEmail={() => {
        setSent(false);
        setError(null);
        setResendSeconds(0);
      }}
      securityCheck={
        sitekey && (
          <VStack gap={2} align="center">
            <Turnstile
              key={challengeVersion}
              siteKey={sitekey}
              options={{
                size: `compact`,
                appearance: `interaction-only`,
                refreshExpired: `auto`,
                responseField: false,
              }}
              scriptOptions={{
                id: `account-signup-turnstile`,
                onError: handleChallengeFailure,
              }}
              onSuccess={(token) => {
                setTurnstileToken(token);
                setChallengeFailed(false);
              }}
              onExpire={() => setTurnstileToken(null)}
              onTimeout={handleChallengeFailure}
              onError={handleChallengeFailure}
              onUnsupported={handleChallengeFailure}
            />
            {challengeFailed ? (
              <VStack gap={2} align="center">
                <Text as="p" variant="error" role="alert" className="text-center">
                  The security check couldn't load. Check your connection and try again.
                </Text>
                <Button type="button" variant="ghost" onClick={resetChallenge}>
                  Retry security check
                </Button>
              </VStack>
            ) : (
              !turnstileToken && (
                <Text as="p" variant="captionMuted" role="status">
                  Completing a quick security check…
                </Text>
              )
            )}
          </VStack>
        )
      }
    />
  );
};

export const Route = createFileRoute(`/(unauthed)/signup`)({
  beforeLoad: () => {
    if (isAuthed()) throw redirect({ to: `/people` });
  },
  component: SignupRoute,
});
