import { Button, LoadingDots } from '@gertrude/ui';
import { createFileRoute, useNavigate } from '@tanstack/react-router';
import React from 'react';
import { authRedirectForPath, postAuthLocation } from '#/lib/authRedirect';
import { setAuth } from '#/pairql/auth';
import { liveClient } from '#/pairql/client';

const VerifySignupEmailRoute: React.FC = () => {
  const { token } = Route.useParams();
  const navigate = useNavigate();
  const started = React.useRef(false);
  const [error, setError] = React.useState<string>();

  React.useEffect(() => {
    if (started.current) return;
    started.current = true;
    void (async () => {
      const result = await liveClient.accountVerifySignupEmail({ token });
      result.with({
        success: ({ accountId, token: accountToken, redirect }) => {
          setAuth(accountId, accountToken);
          void navigate(
            postAuthLocation(redirect ? authRedirectForPath(redirect) : undefined),
          );
        },
        error: (err) => {
          setError(err.userMessage ?? `This verification link is invalid or expired.`);
        },
      });
    })();
  }, [token, navigate]);

  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-4 bg-stone-50 px-6 text-center">
      {error ? (
        <>
          <h1 className="text-xl font-semibold text-stone-950">
            Couldn't verify your email
          </h1>
          <p role="alert" className="max-w-sm text-sm text-stone-700">
            {error}
          </p>
          <Button type="button" onClick={() => window.location.assign(`/login`)}>
            Back to login
          </Button>
        </>
      ) : (
        <>
          <LoadingDots />
          <p role="status" className="text-sm text-stone-700">
            Verifying your email…
          </p>
        </>
      )}
    </main>
  );
};

export const Route = createFileRoute(`/(unauthed)/verify-signup-email/$token`)({
  component: VerifySignupEmailRoute,
});
