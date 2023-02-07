import React from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import type { PqlError } from '@dash/types';
import ErrorMessage from './ErrorMessage';
import GenericError from './GenericError';

interface Props {
  error?: PqlError;
  wrapped?: boolean;
}

const ApiErrorMessage: React.FC<Props> = ({ error, wrapped = true }) => {
  const Wrap = wrapped ? ErrorMessage : React.Fragment;
  const location = useLocation();

  if (error?.userMessage) {
    return <Wrap>{error.userMessage}</Wrap>;
  }
  switch (error?.type) {
    case `notFound`:
      return <Wrap>{error.entityName ? `${error.entityName} not` : `Not`} found.</Wrap>;
    case `loggedOut`:
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
    <Wrap>
      <GenericError />
    </Wrap>
  );
};

export default ApiErrorMessage;
