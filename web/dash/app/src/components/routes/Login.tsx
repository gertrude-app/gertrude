import React from 'react';
import { FullscreenModalForm, LoginForm } from '@dash/components';
import { useDispatch, useSelector } from '../../redux/hooks';
import {
  loginEmailUpdated,
  loginPasswordUpdated,
  submitLoginForm,
  requestMagicLink,
} from '../../redux/slice-auth';
import ApiErrorMessage from '../ApiErrorMessage';
import { Navigate, useLocation } from 'react-router-dom';
import { Req } from '../../redux/helpers';

type Props = React.ComponentProps<typeof LoginForm> & {
  passwordRequest: RequestState;
  magicLinkRequest: RequestState;
};

export const Login: React.FC<Props> = ({
  email,
  setEmail,
  passwordRequest,
  magicLinkRequest,
  onSubmit,
  password,
  setPassword,
  onSendMagicLink,
}) => {
  const location = useLocation();
  if (passwordRequest.state === `ongoing` || magicLinkRequest.state === `ongoing`) {
    return <FullscreenModalForm request="ongoing" />;
  }

  if (magicLinkRequest.state === `succeeded`) {
    return (
      <FullscreenModalForm
        request="succeeded"
        message="Check your email for a magic link."
      />
    );
  }

  if (passwordRequest.state === `succeeded`) {
    return <Navigate to="/" replace state={{ from: location }} />;
  }

  if (passwordRequest.state === `failed` || magicLinkRequest.state === `failed`) {
    return (
      <FullscreenModalForm
        request="failed"
        error={
          <ApiErrorMessage
            wrapped={false}
            error={Req.error(passwordRequest) ?? Req.error(magicLinkRequest)}
          />
        }
      />
    );
  }

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
};

// container

const LoginContainer: React.FC = () => {
  const dispatch = useDispatch();
  const { email, password, passwordRequest, magicLinkRequest } = useSelector((state) => ({
    email: state.auth.loginEmail,
    password: state.auth.loginPassword,
    passwordRequest: state.auth.passwordLoginRequest,
    magicLinkRequest: state.auth.requestMagicLinkRequest,
  }));
  return (
    <Login
      passwordRequest={passwordRequest}
      magicLinkRequest={magicLinkRequest}
      email={email}
      setEmail={(email) => dispatch(loginEmailUpdated(email))}
      password={password}
      setPassword={(password) => dispatch(loginPasswordUpdated(password))}
      onSubmit={() => dispatch(submitLoginForm())}
      onSendMagicLink={() => dispatch(requestMagicLink())}
    />
  );
};

export default LoginContainer;
