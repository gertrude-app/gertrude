import React from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useSelector } from '../redux/hooks';
import Chrome from './Chrome';

const Authed: React.FC<{ children: JSX.Element }> = ({ children }) => {
  const isLoggedIn = useSelector((state) => state.auth.admin !== null);
  const location = useLocation();
  if (!isLoggedIn) {
    return <Navigate to="/login" replace state={{ from: location }} />;
  }
  return children;
};

export default Authed;

export function authed(component: JSX.Element): JSX.Element {
  return (
    <Authed>
      <Chrome>{component}</Chrome>
    </Authed>
  );
}
