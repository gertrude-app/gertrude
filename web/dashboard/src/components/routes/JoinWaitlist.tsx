import React, { useState } from 'react';
import EmailFormScreen from '@shared/EmailFormScreen';
import * as api from '../../api';

type State = React.ComponentProps<typeof EmailFormScreen>['state'];

const JoinWaitlist: React.FC = () => {
  const [state, setState] = useState<State>(`default`);
  const [email, setEmail] = useState(``);

  switch (state) {
    case `fetching`:
      return <EmailFormScreen state="fetching" />;

    case `success`:
      return (
        <EmailFormScreen
          state="success"
          message="Thanks! We'll send an email when you can sign up."
        />
      );

    case `error`:
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
          onSubmit={async () => {
            setState(`fetching`);
            const mutation = await api.signup.createWaitlistedUser(email);
            setState(mutation.result.type);
          }}
        />
      );
  }
};

export default JoinWaitlist;
