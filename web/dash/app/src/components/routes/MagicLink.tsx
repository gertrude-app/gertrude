import React, { useEffect } from 'react';
import { ApiErrorMessage, FullscreenModalForm } from '@dash/components';
import { Navigate, useLocation, useParams } from 'react-router-dom';
import { useDispatch, useSelector } from '../../redux/hooks';
import { loginFromMagicLink } from '../../redux/slice-auth';
import useLoginRedirect from '../../hooks/login-redirect';

const MagicLink: React.FC = () => {
  const { token = `` } = useParams<{ token: string }>();
  const location = useLocation();
  const dispatch = useDispatch();
  const request = useSelector((state) => state.auth.loginFromMagicLinkRequest);
  const redirectUrl = useLoginRedirect();

  useEffect(() => {
    dispatch(loginFromMagicLink({ token }));
  }, [dispatch, token]);

  switch (request.state) {
    case `idle`:
    case `ongoing`:
      return <FullscreenModalForm request="ongoing" />;

    case `succeeded`:
      return <Navigate to={redirectUrl ?? `/`} replace state={{ from: location }} />;

    case `failed`: {
      let error: React.ReactNode = (
        <ApiErrorMessage wrapped={false} error={request.error} />
      );
      if (request.error?.tag === `magicLinkTokenNotFound`) {
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
  }
};

export default MagicLink;
