import React, { useEffect } from 'react';
import FullscreenModalForm from '@dashboard/Unauthed/FullscreenModalForm';
import EmailInputForm from '@dashboard/Unauthed/EmailInputForm';
import { useDispatch, useSelector } from '../../redux/hooks';
import {
  allowingSignups,
  emailUpdated,
  joinWaitlist,
  sendVerificationEmail,
} from '../../redux/slice-signup';

const Signup: React.FC = () => {
  const dispatch = useDispatch();
  const email = useSelector((state) => state.signup.email);
  const verifyReq = useSelector((state) => state.signup.sendVerificationEmailReq);
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
    verifyReq.state === `ongoing`
  ) {
    return <FullscreenModalForm request="ongoing" />;
  }

  if (allowReqState === `failed` || verifyReq.state === `failed`) {
    return (
      <FullscreenModalForm
        request="failed"
        error="Shucks! Something went wrong, please try again."
      />
    );
  }

  if (verifyReq.state === `succeeded`) {
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
          title="Sign up"
          subTitle="Enter your emaill address so we can send you a verification email"
          email={email}
          setEmail={(email) => dispatch(emailUpdated(email))}
          onSubmit={() => dispatch(sendVerificationEmail(email))}
        />
      )}
    </FullscreenModalForm>
  );
};

export default Signup;
