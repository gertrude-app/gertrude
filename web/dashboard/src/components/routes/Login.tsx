import React from 'react';
import FullscreenModalForm from '@shared/dashboard/Unauthed/FullscreenModalForm';
import LoginForm from '@shared/dashboard/Unauthed/LoginForm';
import { useDispatch, useSelector } from '../../redux/hooks';
import {
  loginEmailUpdated,
  loginPasswordUpdated,
  submitLoginForm,
  requestMagicLink,
} from '../../redux/slice-auth';
import ApiErrorMessage from '../ApiErrorMessage';
import { Navigate, useLocation } from 'react-router-dom';

type Props = React.ComponentProps<typeof LoginForm> & {
  request: RequestState;
  receivedAdmin: boolean;
};

export const Login: React.FC<Props> = ({
  email,
  setEmail,
  request,
  onSubmit,
  password,
  setPassword,
  receivedAdmin,
  onSendMagicLink,
}) => {
  const location = useLocation();
  switch (request.state) {
    case `ongoing`:
      return <FullscreenModalForm request="ongoing" />;

    case `succeeded`:
      if (receivedAdmin) {
        return <Navigate to="/" replace state={{ from: location }} />;
      } else {
        return (
          <FullscreenModalForm
            request="succeeded"
            message="Check your email for a magic link."
          />
        );
      }

    case `failed`:
      return (
        <FullscreenModalForm
          request="failed"
          error={<ApiErrorMessage wrapped={false} error={request.error} />}
        />
      );

    default:
      return (
        <FullscreenModalForm request="idle">
          <LoginForm
            email={email}
            setEmail={setEmail}
            password={password}
            setPassword={setPassword}
            onSubmit={onSubmit}
            onSendMagicLink={onSendMagicLink}
          />
        </FullscreenModalForm>
      );
  }
};

// container

const LoginContainer: React.FC = () => {
  const dispatch = useDispatch();
  const { email, password, request, receivedAdmin } = useSelector((state) => ({
    email: state.auth.loginEmail,
    password: state.auth.loginPassword,
    request: state.auth.loginRequest,
    receivedAdmin: state.auth.admin != null,
  }));
  return (
    <Login
      request={request}
      email={email}
      setEmail={(email) => dispatch(loginEmailUpdated(email))}
      password={password}
      setPassword={(password) => dispatch(loginPasswordUpdated(password))}
      onSubmit={() => dispatch(submitLoginForm())}
      receivedAdmin={receivedAdmin}
      onSendMagicLink={() => dispatch(requestMagicLink())}
    />
  );
};

export default LoginContainer;
