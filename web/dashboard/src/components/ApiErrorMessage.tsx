import React from 'react';
import ErrorMessage from '@dashboard/ErrorMessage';
import { Link } from 'react-router-dom';
import { useDispatch } from '../redux/hooks';
import { logoutClicked } from '../redux/slice-auth';

interface Props {
  error?: ApiError;
  wrapped?: boolean;
}

const ApiErrorMessage: React.FC<Props> = ({ error, wrapped = true }) => {
  const Wrap = wrapped ? ErrorMessage : React.Fragment;
  const dispatch = useDispatch();
  switch (error?.type) {
    case `no_internet`:
      return <Wrap>No internet connection</Wrap>;
    case `actionable`:
      return <Wrap>{error.message}</Wrap>;
    case undefined: /* fallthrough */
    case `non_actionable`:
      return <Wrap>Something went wrong! Please try again.</Wrap>;
    case `auth_failed`:
      return (
        <Wrap>
          Your session expired. Please{` `}
          <Link
            to="/login"
            className="underline text-blue-700 hover:text-blue-600"
            onClick={() => dispatch(logoutClicked())}
          >
            login again.
          </Link>
        </Wrap>
      );
  }
};

export default ApiErrorMessage;
