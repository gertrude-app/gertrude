import React from 'react';
import { Navigate, Outlet, useLocation } from 'react-router-dom';
import { useAuth } from '../hooks/auth';
import Chrome from './Chrome';

const Authed: React.FC = () => {
  const { admin } = useAuth();
  const location = useLocation();
  if (admin === null) {
    return (
      <Navigate
        to={`/logout${
          location.pathname === `/`
            ? ``
            : `?redirect=${encodeURIComponent(location.pathname)}`
        }`}
        replace
        state={{ from: location }}
      />
    );
  }
  return (
    <Chrome>
      <Outlet />
    </Chrome>
  );
};

export default Authed;
