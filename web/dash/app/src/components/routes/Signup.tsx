import React, { useEffect } from 'react';
import { FullscreenModalForm, EmailInputForm } from '@dash/components';
import { useDispatch, useSelector } from '../../redux/hooks';
import {
  allowingSignups,
  emailUpdated,
  passwordUpdated,
  joinWaitlist,
  initiateSignup,
} from '../../redux/slice-signup';
import { Link } from 'react-router-dom';

const Signup: React.FC = () => {
  const dispatch = useDispatch();
  const email = useSelector((state) => state.signup.email);
  const password = useSelector((state) => state.signup.password);
  const signupReq = useSelector((state) => state.signup.signupReq);
  const allowReq = useSelector((state) => state.signup.allowingSignupsReq);
  const allowReqState = allowReq.state;

  useEffect(() => {
    if (allowReqState === `idle`) {
      dispatch(allowingSignups());
    }
  }, [dispatch, allowReqState]);

  if (
    allowReqState === `ongoing` ||
    allowReqState === `idle` ||
    signupReq.state === `ongoing`
  ) {
    return <FullscreenModalForm request="ongoing" />;
  }

  if (allowReqState === `failed` || signupReq.state === `failed`) {
    return (
      <FullscreenModalForm
        request="failed"
        error="Shucks! Something went wrong, please try again."
      />
    );
  }

  if (signupReq.state === `succeeded`) {
    const url = signupReq.payload;
    if (url) {
      // redirect to stripe flow
      window.location.href = url;
      return <FullscreenModalForm request="ongoing" />;
    }

    return (
      <FullscreenModalForm
        request="succeeded"
        message="Verification email sent! Please check your inbox."
      />
    );
  }

  return (
    <FullscreenModalForm request="idle">
      {allowReq.payload === false ? (
        <EmailInputForm
          title="Join the waitlist"
          subTitle="We'll notify you when you can begin trying out Gertrude"
          email={email}
          setEmail={(email) => dispatch(emailUpdated(email))}
          onSubmit={() => dispatch(joinWaitlist(email))}
        />
      ) : (
        <EmailInputForm
          title="Signup"
          subTitle={
            <>
              Got an account?{` `}
              <Link
                className="text-violet-700 border-b border-dotted border-violet-700"
                to="/login"
              >
                Login
              </Link>
              {` `}
              instead.
            </>
          }
          email={email}
          setEmail={(email) => dispatch(emailUpdated(email))}
          password={password}
          setPassword={(password) => dispatch(passwordUpdated(password))}
          onSubmit={() => dispatch(initiateSignup({ email, password }))}
        />
      )}
    </FullscreenModalForm>
  );
};

export default Signup;
