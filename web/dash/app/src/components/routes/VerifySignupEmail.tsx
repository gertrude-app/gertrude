import { FullscreenModalForm, claimFunnelPath } from '@dash/components';
import { Button } from '@shared/components';
import React from 'react';
import { Navigate, useParams } from 'react-router-dom';
import Current from '../../environment';
import { useAuth, useFireAndForget, useLoginRedirect } from '../../hooks';

const VerifySignupEmail: React.FC = () => {
  const { token = `` } = useParams<{ token: UUID }>();
  const { login } = useAuth();
  const redirect = useLoginRedirect();

  const verification = useFireAndForget(() => Current.api.verifySignupEmail({ token }), {
    onReceive: ({ adminId, token }) => login(adminId, token),
  });

  if (verification.isError && verification.error.tag === `emailAlreadyVerified`) {
    return (
      <FullscreenModalForm state="custom">
        <>
          <p className="text-center sm:text-left text-slate-500">
            Your email address has already been verified.
          </p>
          <Button color="secondary" type="link" to="/login" className="mt-5">
            Login now &rarr;
          </Button>
        </>
      </FullscreenModalForm>
    );
  }

  if (verification.isError) {
    return (
      <FullscreenModalForm
        state="failed"
        error={verification.error.userMessage ?? `Failed to verify email address.`}
      />
    );
  }

  if (verification.isPending) {
    return <FullscreenModalForm state="ongoing" />;
  }

  const claimCode = verification.data?.claimCode;
  const claimIntent = verification.data?.claimIntent ?? `blockerSupervise`;
  const destination =
    redirect ?? (claimCode ? claimFunnelPath(claimIntent, claimCode) : `/`);
  return (
    <Navigate to={`/referral-survey?next=${encodeURIComponent(destination)}`} replace />
  );
};

export default VerifySignupEmail;
