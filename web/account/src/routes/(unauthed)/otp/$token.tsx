import { LoadingDots, toast } from '@gertrude/ui';
import { createFileRoute, useNavigate } from '@tanstack/react-router';
import React, { useEffect, useRef } from 'react';
import { postAuthLocation, validateAuthRedirectSearch } from '#/lib/authRedirect';
import { setAuth } from '#/pairql/auth';
import { liveClient } from '#/pairql/client';

const OtpPage: React.FC = () => {
  const { token } = Route.useParams();
  const { redirect: authRedirect } = Route.useSearch();
  const navigate = useNavigate();
  const consumed = useRef(false);

  useEffect(() => {
    if (consumed.current) return;
    consumed.current = true;
    void (async () => {
      const result = await liveClient.accountLoginMagicLink({ token });
      result.with({
        success: ({ accountId, token: authToken }) => {
          setAuth(accountId, authToken);
          void navigate(postAuthLocation(authRedirect));
        },
        error: () => {
          toast.error(`That sign-in link is invalid or expired — please try again.`);
          void navigate({
            to: `/login`,
            search: { redirect: authRedirect },
          });
        },
      });
    })();
  }, [token, authRedirect, navigate]);

  return (
    <div className="flex min-h-screen items-center justify-center bg-stone-50">
      <LoadingDots />
    </div>
  );
};

export const Route = createFileRoute(`/(unauthed)/otp/$token`)({
  validateSearch: validateAuthRedirectSearch,
  component: OtpPage,
});
