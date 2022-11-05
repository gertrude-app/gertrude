import React from 'react';
import { FullscreenModalForm, EmailInputForm } from '@dash/components';
import { useDispatch, useSelector } from '../../redux/hooks';
import { emailUpdated, joinWaitlist } from '../../redux/slice-signup';

interface Props {
  request: RequestState;
  email: string;
  setEmail(email: string): unknown;
  submit(): unknown;
}

export const JoinWaitlist: React.FC<Props> = ({ email, setEmail, request, submit }) => {
  switch (request.state) {
    case `ongoing`:
      return <FullscreenModalForm request="ongoing" />;

    case `succeeded`:
      return (
        <FullscreenModalForm
          request="succeeded"
          message="Thanks! We'll send an email when you can sign up."
        />
      );

    case `failed`:
      return (
        <FullscreenModalForm
          request="failed"
          error="Shucks! Something went wrong, please try again."
        />
      );

    default:
      return (
        <FullscreenModalForm request="idle">
          <EmailInputForm
            title="Join the waitlist"
            subTitle="We'll notify you when you can begin trying out Gertrude"
            email={email}
            setEmail={setEmail}
            onSubmit={submit}
          />
        </FullscreenModalForm>
      );
  }
};

// container

const JoinWaitlistContainer: React.FC = () => {
  const dispatch = useDispatch();
  const email = useSelector((state) => state.signup.email);
  const request = useSelector((state) => state.signup.joinWaitlistReq);
  return (
    <JoinWaitlist
      request={request}
      email={email}
      setEmail={(email) => dispatch(emailUpdated(email))}
      submit={() => dispatch(joinWaitlist(email))}
    />
  );
};

export default JoinWaitlistContainer;
