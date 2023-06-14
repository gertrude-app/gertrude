import React from 'react';
import { FullscreenModalForm } from '@dash/components';
import { useParams } from 'react-router-dom';
import { useFireAndForget } from '../../hooks';
import Current from '../../environment';

const VerifySignupEmail: React.FC = () => {
  const { token = `` } = useParams<{ token: UUID }>();

  const verifyEmail = useFireAndForget(() => Current.api.verifySignupEmail({ token }));

  const getCheckoutUrl = useFireAndForget(
    () => Current.api.getCheckoutUrl({ adminId: verifyEmail.data?.adminId ?? `` }),
    { when: verifyEmail.isSuccess },
  );

  if (verifyEmail.isError) {
    return <FullscreenModalForm request="failed" error="Failed to verify your email." />;
  }

  if (getCheckoutUrl.isError) {
    return (
      <FullscreenModalForm request="failed" error="Unexpected error, please try again." />
    );
  }

  if (verifyEmail.isLoading || getCheckoutUrl.isLoading) {
    return <FullscreenModalForm request="ongoing" />;
  }

  window.location.href = getCheckoutUrl.data.url;
  return <FullscreenModalForm request="ongoing" text="Redirecting to trial setup..." />;
};

export default VerifySignupEmail;
