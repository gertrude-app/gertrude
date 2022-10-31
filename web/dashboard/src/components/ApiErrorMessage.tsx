import React from 'react';
import ErrorMessage from '@dashboard/ErrorMessage';
import { Link } from 'react-router-dom';
import { useDispatch } from '../redux/hooks';
import { logoutClicked } from '../redux/slice-auth';

interface Props {
  error?: ApiError;
  wrapped?: boolean;
  entity?: string;
}

const ApiErrorMessage: React.FC<Props> = ({ error, entity, wrapped = true }) => {
  const Wrap = wrapped ? ErrorMessage : React.Fragment;
  const dispatch = useDispatch();
  switch (error?.type) {
    case `no_internet`:
      return <Wrap>No internet connection</Wrap>;
    case `actionable`:
      return <Wrap>{error.message}</Wrap>;
    case undefined: /* fallthrough */
    case `not_found`:
      return <Wrap>{entity ? `${entity} not` : `Not`} found.</Wrap>;
    case `non_actionable`:
      return (
        <Wrap>
          Sorry, there&rsquo;s been some sort of technical glitch (probably on our end).
          Please try again, or
          {` `}
          <a className="text-red-800 underline" href="https://gertrude.app/contact">
            contact support
          </a>
          {` `}
          if the problem persists.
        </Wrap>
      );
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
