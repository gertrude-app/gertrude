import React from 'react';
import { Link } from 'react-router-dom';
import ErrorMessage from './ErrorMessage';
import GenericError from './GenericError';

interface Props {
  error?: ApiError;
  wrapped?: boolean;
  entity?: string;
}

const ApiErrorMessage: React.FC<Props> = ({ error, entity, wrapped = true }) => {
  const Wrap = wrapped ? ErrorMessage : React.Fragment;
  switch (error?.type) {
    case `no_internet`:
      return (
        <Wrap>
          Something seems funny with the network. Are you sure you're connected to the
          internet?
        </Wrap>
      );
    case `actionable`:
      return <Wrap>{error.message}</Wrap>;
    case `not_found`:
      return <Wrap>{entity ? `${entity} not` : `Not`} found.</Wrap>;
    case undefined: /* fallthrough */
    case `non_actionable`:
      return (
        <Wrap>
          <GenericError />
        </Wrap>
      );
    case `auth_failed`:
      return (
        <Wrap>
          Your session expired. Please{` `}
          <Link to="/logout" className="underline text-blue-700 hover:text-blue-600">
            login again.
          </Link>
        </Wrap>
      );
  }
};

export default ApiErrorMessage;
