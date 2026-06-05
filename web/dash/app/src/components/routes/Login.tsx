import {
  ApiErrorMessage,
  DeviceContextBanner,
  FullscreenModalForm,
  LoginForm,
  detectClaimPending,
} from '@dash/components';
import React, { useState } from 'react';
import { Navigate, useSearchParams } from 'react-router-dom';
import Current from '../../environment';
import { useAuth, useLoginRedirect, useMutation } from '../../hooks';

export const Login: React.FC = () => {
  const { admin, login } = useAuth();
  const redirectUrl = useLoginRedirect() ?? `/`;
  const [email, setEmail] = useState(``);
  const [password, setPassword] = useState(``);
  const [searchParams] = useSearchParams();
  const fromPage = searchParams.get(`from`);
  const pendingClaim = detectClaimPending(searchParams);
  const claimCode = pendingClaim?.claimCode;
  const app = pendingClaim?.app;
  const modelName = searchParams.get(`modelName`);
  const iosVersion = searchParams.get(`iosVersion`);

  const requestMagicLink = useMutation(() =>
    Current.api.requestMagicLink({
      email,
      redirect: new URLSearchParams(window.location.search).get(`redirect`) ?? undefined,
    }),
  );

  const loginMutation = useMutation(() => Current.api.login({ email, password }), {
    onSuccess: ({ adminId, token }) => login(adminId, token),
  });

  if (admin !== null || loginMutation.isSuccess) {
    return <Navigate to={redirectUrl} replace />;
  }

  if (loginMutation.isPending || requestMagicLink.isPending) {
    return <FullscreenModalForm state="ongoing" />;
  }

  if (requestMagicLink.isSuccess) {
    return (
      <FullscreenModalForm
        state="succeeded"
        message="Check your email for a magic link."
      />
    );
  }

  if (loginMutation.isError || requestMagicLink.isError) {
    return (
      <FullscreenModalForm
        state="failed"
        error={
          <ApiErrorMessage
            wrapped={false}
            error={loginMutation.error ?? requestMagicLink.error ?? undefined}
          />
        }
      />
    );
  }

  return (
    <FullscreenModalForm state="idle">
      <LoginForm
        email={email}
        setEmail={setEmail}
        password={password}
        setPassword={setPassword}
        onSubmit={() => loginMutation.mutate(undefined)}
        onSendMagicLink={() => requestMagicLink.mutate(undefined)}
        fromPasswordReset={fromPage === `reset`}
        signupUrl={`/signup${window.location.search}`}
        beforeInputs={
          claimCode && modelName ? (
            <DeviceContextBanner
              modelName={modelName}
              iosVersion={iosVersion ?? undefined}
              app={app}
              label="Login to connect:"
            />
          ) : undefined
        }
      />
    </FullscreenModalForm>
  );
};

export default Login;
