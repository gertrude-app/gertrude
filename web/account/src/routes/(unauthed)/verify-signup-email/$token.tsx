import { createFileRoute, useNavigate } from '@tanstack/react-router';
import React from 'react';
import VerifySignupEmailPage, {
  type VerificationState,
} from '#/components/pages/unauthed/VerifySignupEmailPage';
import { setAuth } from '#/pairql/auth';
import { liveClient } from '#/pairql/client';

const VerifySignupEmailRoute: React.FC = () => {
  const { token } = Route.useParams();
  const navigate = useNavigate();
  const [state, setState] = React.useState<VerificationState>({ status: `verifying` });
  const [attempt, setAttempt] = React.useState(0);
  const request = React.useRef<{
    key: string;
    result: ReturnType<typeof liveClient.accountVerifySignupEmail>;
  } | null>(null);

  React.useEffect(() => {
    const requestKey = `${token}:${attempt}`;
    if (request.current?.key !== requestKey) {
      request.current = {
        key: requestKey,
        result: liveClient.accountVerifySignupEmail({ token }),
      };
    }
    let active = true;
    setState({ status: `verifying` });
    void request.current.result.then((result) => {
      if (!active) return;
      result.with({
        success: ({ accountId, token: authToken }) => {
          setAuth(accountId, authToken);
          void navigate({ to: `/people`, replace: true });
        },
        error: (error) => {
          setState(
            error.tag === `emailAlreadyVerified`
              ? { status: `alreadyVerified` }
              : {
                  status: `error`,
                  message:
                    error.userMessage ??
                    (error.type === `notFound` || error.type === `badRequest`
                      ? `This verification link is invalid or no longer available. Sign up again to receive a new email.`
                      : `We couldn't reach Gertrude to verify your email. Check your connection and try again.`),
                  retryable: ![`notFound`, `badRequest`].includes(error.type),
                },
          );
        },
      });
    });
    return () => {
      active = false;
    };
  }, [token, attempt, navigate]);

  return (
    <VerifySignupEmailPage
      state={state}
      onRetry={() => setAttempt((value) => value + 1)}
    />
  );
};

export const Route = createFileRoute(`/(unauthed)/verify-signup-email/$token`)({
  component: VerifySignupEmailRoute,
});
