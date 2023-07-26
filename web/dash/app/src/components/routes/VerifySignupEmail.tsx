import React from 'react';
import { FullscreenModalForm } from '@dash/components';
import { Navigate, useParams } from 'react-router-dom';
import { useAuth, useFireAndForget } from '../../hooks';
import Current from '../../environment';

const VerifySignupEmail: React.FC = () => {
  const { token = `` } = useParams<{ token: UUID }>();
  const { login } = useAuth();

  const verifyEmail = useFireAndForget(() => Current.api.verifySignupEmail({ token }), {
    onReceive: ({ adminId, token }) => login(adminId, token),
  });

  if (verifyEmail.isError) {
    return <FullscreenModalForm request="failed" error="Failed to verify your email." />;
  }

  if (verifyEmail.isLoading) {
    return <FullscreenModalForm request="ongoing" />;
  }

  return <Navigate to="/" replace />;
};

export default VerifySignupEmail;
