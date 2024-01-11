import React, { useState } from 'react';
import { FullscreenModalForm, EmailInputForm } from '@dash/components';
import { Link } from 'react-router-dom';
import { useMutation } from '../../hooks';
import Current from '../../environment';

const Signup: React.FC = () => {
  const [email, setEmail] = useState(``);
  const [password, setPassword] = useState(``);
  const signup = useMutation(() => Current.api.signup({ email, password }));

  if (signup.isPending) {
    return <FullscreenModalForm state="ongoing" />;
  }

  if (signup.isError) {
    return (
      <FullscreenModalForm
        state="failed"
        error="Shucks! Something went wrong, please try again."
      />
    );
  }

  if (signup.isSuccess) {
    return (
      <FullscreenModalForm
        state="succeeded"
        message="Verification email sent! Please check your inbox."
      />
    );
  }

  return (
    <FullscreenModalForm state="idle">
      <EmailInputForm
        id="signup"
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
        setEmail={setEmail}
        password={password}
        setPassword={setPassword}
        onSubmit={() => signup.mutate(undefined)}
      />
    </FullscreenModalForm>
  );
};

export default Signup;
