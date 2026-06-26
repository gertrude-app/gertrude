import {
  CLAIM_REDIRECT_ROUTE,
  FullscreenModalForm,
  detectClaimFunnelPath,
} from '@dash/components';
import { useQueryClient } from '@tanstack/react-query';
import React, { useEffect } from 'react';
import { Navigate } from 'react-router-dom';
import Current from '../../environment';
import { useAuth } from '../../hooks/auth';

const Logout: React.FC = () => {
  const { logout } = useAuth();
  const queryClient = useQueryClient();
  const redirect = new URLSearchParams(window.location.search).get(`redirect`);
  const pendingClaim = redirect ? detectClaimFunnelPath(redirect) : null;
  const claimRedirectUrl = pendingClaim
    ? `${Current.env.apiEndpoint()}/${CLAIM_REDIRECT_ROUTE[pendingClaim.intent]}/${pendingClaim.claimCode}`
    : null;

  useEffect(() => {
    logout();
    queryClient.clear();
    if (claimRedirectUrl) {
      window.location.replace(claimRedirectUrl);
    }
  }, [logout, queryClient, claimRedirectUrl]);

  if (claimRedirectUrl) {
    return <FullscreenModalForm state="ongoing" />;
  }

  return <Navigate to={`/login${window.location.search}`} replace />;
};

export default Logout;
