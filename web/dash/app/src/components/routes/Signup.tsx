import { EmailInputForm, FullscreenModalForm } from '@dash/components';
import React, { useState } from 'react';
import { Navigate } from 'react-router-dom';
import { Link, useNavigate } from 'react-router-dom';
import Turnstile from 'react-turnstile';
import Current from '../../environment';
import { useAuth, useMutation, useTimeout } from '../../hooks';

const Signup: React.FC = () => {
  const { admin, login } = useAuth();
  const [email, setEmail] = useState(``);
  const [password, setPassword] = useState(``);
  const [turnstileToken, setTurnstileToken] = useState<string | null>(null);
  const navigate = useNavigate();
  const signup = useMutation(
    () =>
      Current.api.signup({
        email,
        password,
        gclid: getCookieValue(`gclid`),
        abTestVariant: getQueryParam(`v`) ?? getCookieValue(`ab_variant`),
        turnstileToken: turnstileToken ?? undefined,
      }),
    { onSuccess: ({ admin }) => admin && login(admin.adminId, admin.token) },
  );

  useTimeout(
    () => navigate(`/login`),
    7500,
    signup.isSuccess && signup.data?.admin === undefined,
  );

  if (admin !== null || (signup.isSuccess && signup.data?.admin !== undefined)) {
    return <Navigate to="/" replace />;
  }

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
      <Turnstile
        sitekey={Current.env.turnstileSitekey()}
        size="invisible"
        refreshExpired="auto"
        onVerify={setTurnstileToken}
      />
    </FullscreenModalForm>
  );
};

export default Signup;

function getCookieValue(name: string): string | undefined {
  return document.cookie.match(`(^|;)\\s*` + name + `\\s*=\\s*([^;]+)`)?.pop();
}

function getQueryParam(name: string): string | undefined {
  const url = new URL(window.location.href);
  return url.searchParams.get(name) ?? undefined;
}
