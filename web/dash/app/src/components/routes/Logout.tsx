import { useQueryClient } from '@tanstack/react-query';
import React, { useEffect } from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '../../hooks/auth';

const Logout: React.FC = () => {
  const { logout } = useAuth();
  const queryClient = useQueryClient();

  useEffect(() => {
    logout();
    queryClient.clear();
  }, [logout, queryClient]);

  return <Navigate to={`/login${window.location.search}`} replace />;
};

export default Logout;
