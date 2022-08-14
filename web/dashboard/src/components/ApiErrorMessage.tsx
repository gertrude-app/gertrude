import React from 'react';
import ErrorMessage from '@shared/dashboard/ErrorMessage';
import { Link } from 'react-router-dom';
import { useDispatch } from '../redux/hooks';
import { logoutClicked } from '../redux/slice-auth';

interface Props {
  error?: ApiError;
}

const ApiErrorMessage: React.FC<Props> = ({ error }) => {
  const dispatch = useDispatch();
  switch (error?.type) {
    case `no_internet`:
      return <ErrorMessage>No internet connection</ErrorMessage>;
    case `actionable`:
      return <ErrorMessage>{error.message}</ErrorMessage>;
    case undefined: /* fallthrough */
    case `non_actionable`:
      return <ErrorMessage>Something went wrong! Please try again.</ErrorMessage>;
    case `auth_failed`:
      return (
        <ErrorMessage>
          Your session expired. Please{` `}
          <Link
            to="/login"
            className="underline text-blue-700 hover:text-blue-600"
            onClick={() => dispatch(logoutClicked())}
          >
            login again.
          </Link>
        </ErrorMessage>
      );
  }
};

export default ApiErrorMessage;
