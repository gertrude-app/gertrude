import React, { useEffect } from 'react';
import { Navigate } from 'react-router-dom';
import { useDispatch } from '../../redux/hooks';
import { logoutRouteVisited } from '../../redux/slice-auth';

const Logout: React.FC = () => {
  const dispatch = useDispatch();

  useEffect(() => {
    dispatch(logoutRouteVisited());
  }, [dispatch]);

  return <Navigate to={`/login${window.location.search}`} replace />;
};

export default Logout;
