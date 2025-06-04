import { ApiErrorMessage, FullscreenModalForm } from '@dash/components';
import React from 'react';
import { Link, Navigate, useLocation, useParams } from 'react-router-dom';
import Current from '../../environment';
import { useFireAndForget, useLoginRedirect } from '../../hooks';
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
          <Link to="/login" className="underline text-blue-700 hover:text-blue-600">
            try again.
          </Link>
        </span>
      );
    }
    return <FullscreenModalForm state="failed" error={error} />;
  }

  if (query.isPending) {
    return <FullscreenModalForm state="ongoing" />;
  }

  return <Navigate to={redirectUrl ?? `/`} replace state={{ from: location }} />;
};

export default MagicLink;
