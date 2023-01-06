import React from 'react';
import { Link } from 'react-router-dom';
import type { PqlError } from '@dash/types';
import ErrorMessage from './ErrorMessage';
import GenericError from './GenericError';

interface Props {
  error?: PqlError;
  wrapped?: boolean;
}

const ApiErrorMessage: React.FC<Props> = ({ error, wrapped = true }) => {
  const Wrap = wrapped ? ErrorMessage : React.Fragment;
  if (error?.userMessage) {
    return <Wrap>{error.userMessage}</Wrap>;
  }
  switch (error?.type) {
    case `notFound`:
      return <Wrap>{error.entityName ? `${error.entityName} not` : `Not`} found.</Wrap>;
    case `loggedOut`:
      return (
        <Wrap>
          Your session expired. Please{` `}
          <Link to="/logout" className="underline text-blue-700 hover:text-blue-600">
            login again.
          </Link>
        </Wrap>
      );
  }
  return (
    <Wrap>
      <GenericError />
    </Wrap>
  );
};

export default ApiErrorMessage;
