import {
  DeviceContextBanner,
  EmailInputForm,
  FullscreenModalForm,
  claimIntentApp,
  detectClaimPending,
} from '@dash/components';
import React, { useState } from 'react';
import { Navigate } from 'react-router-dom';
import { Link } from 'react-router-dom';
import Turnstile from 'react-turnstile';
import Current from '../../environment';
import { useAuth, useLoginRedirect, useMutation } from '../../hooks';

const Signup: React.FC = () => {
  const { admin, login } = useAuth();
  const redirectUrl = useLoginRedirect() ?? `/`;
  const [email, setEmail] = useState(``);
  const [password, setPassword] = useState(``);
  const [turnstileToken, setTurnstileToken] = useState<string | null>(null);
  const queryString = window.location.search;
  const pendingClaim = detectClaimPending(new URLSearchParams(queryString));
  const claimCode = pendingClaim?.claimCode;
  const intent = pendingClaim?.intent;
  const app = intent ? claimIntentApp(intent) : undefined;
  const modelName = getQueryParam(`modelName`);
  const iosVersion = getQueryParam(`iosVersion`);
  const signup = useMutation(
    () =>
      Current.api.signup({
        email,
        password,
        gclid: getCookieValue(`gclid`),
        abTestVariant: getQueryParam(`v`) ?? getCookieValue(`ab_variant`),
        referralCode: getQueryParam(`ref`) ?? getCookieValue(`referral_code`),
        turnstileToken: turnstileToken ?? undefined,
        claimCode,
        intent,
      }),
    { onSuccess: ({ admin }) => admin && login(admin.adminId, admin.token) },
  );

  if (admin !== null || (signup.isSuccess && signup.data?.admin !== undefined)) {
    return <Navigate to={redirectUrl} replace />;
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
              to={`/login${queryString}`}
            >
              Login
            </Link>
            {` `}
            instead.
          </>
        }
        beforeInputs={
          claimCode && modelName ? (
            <DeviceContextBanner
              modelName={modelName}
              iosVersion={iosVersion}
              app={app}
            />
          ) : undefined
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
