import { ApiErrorMessage, FullscreenModalForm } from '@dash/components';
import { Navigate, useLocation, useParams } from 'react-router-dom';
import React from 'react';
import { useFireAndForget, useLoginRedirect } from '../../hooks';
import Current from '../../environment';
import { useAuth } from '../../hooks/auth';

const MagicLink: React.FC = () => {
  const { token = `` } = useParams<{ token: string }>();
  const location = useLocation();
  const { login } = useAuth();
  const redirectUrl = useLoginRedirect();

  const query = useFireAndForget(() => Current.api.loginMagicLink({ token }), {
    onReceive: ({ adminId, token }) => login(adminId, token),
  });

  if (query.isError) {
    let error: React.ReactNode = <ApiErrorMessage wrapped={false} error={query.error} />;
    if (query.error.tag === `magicLinkTokenNotFound`) {
      error = (
        <span className="text-slate-900 antialiased">
          Magic Link token not found, or expired. Please{` `}
          <a href="/login" className="underline text-blue-700 hover:text-blue-600">
            try again.
          </a>
        </span>
      );
    }
    return <FullscreenModalForm request="failed" error={error} />;
  }

  if (query.isLoading) {
    return <FullscreenModalForm request="ongoing" />;
  }

  return <Navigate to={redirectUrl ?? `/`} replace state={{ from: location }} />;
};

export default MagicLink;
