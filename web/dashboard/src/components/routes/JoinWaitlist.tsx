import React from 'react';
import EmailFormScreen from '@shared/dashboard/EmailFormScreen';
import { useDispatch, useSelector } from '../../redux/hooks';
import { emailUpdated, joinWaitlist } from '../../redux/slice-waitlist';

interface Props {
  requestState: RequestState;
  email: string;
  setEmail(email: string): unknown;
  submit(): unknown;
}

export const JoinWaitlist: React.FC<Props> = ({
  email,
  setEmail,
  requestState,
  submit,
}) => {
  switch (requestState) {
    case `ongoing`:
      return <EmailFormScreen state="fetching" />;

    case `succeeded`:
      return (
        <EmailFormScreen
          state="success"
          message="Thanks! We'll send an email when you can sign up."
        />
      );

    case `failed`:
      return (
        <EmailFormScreen
          state="error"
          error="Shucks! Something went wrong, please try again."
        />
      );

    default:
      return (
        <EmailFormScreen
          state="default"
          title="Join the waitlist"
          subTitle="We'll notify you when you can begin trying out Gertrude"
          email={email}
          setEmail={setEmail}
          onSubmit={submit}
        />
      );
  }
};

// container

const JoinWaitlistContainer: React.FC = () => {
  const dispatch = useDispatch();
  const email = useSelector((state) => state.waitlist.email);
  const requestState = useSelector((state) => state.waitlist.requestState);
  return (
    <JoinWaitlist
      requestState={requestState}
      email={email}
      setEmail={(email) => dispatch(emailUpdated(email))}
      submit={() => dispatch(joinWaitlist(email))}
    />
  );
};

export default JoinWaitlistContainer;
