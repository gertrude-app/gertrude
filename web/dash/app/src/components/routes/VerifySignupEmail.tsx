import React from 'react';
import { FullscreenModalForm } from '@dash/components';
import { Navigate, useParams } from 'react-router-dom';
import { Button } from '@shared/components';
import { useAuth, useFireAndForget } from '../../hooks';
import Current from '../../environment';

const VerifySignupEmail: React.FC = () => {
  const { token = `` } = useParams<{ token: UUID }>();
  const { login } = useAuth();

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

  return <Navigate to="/" replace />;
};

export default VerifySignupEmail;
