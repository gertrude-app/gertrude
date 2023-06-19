import React from 'react';
import { Link } from 'react-router-dom';
import { Logo, TextInput, Button } from '@shared/components';

type Props = {
  password: string;
  setPassword(password: string): unknown;
  email: string;
  setEmail(email: string): unknown;
  onSubmit(): unknown;
  onSendMagicLink(): unknown;
  fromPasswordReset?: boolean;
};

const LoginForm: React.FC<Props> = ({
  email,
  setEmail,
  onSubmit,
  setPassword,
  password,
  onSendMagicLink,
  fromPasswordReset = false,
}) => (
  <form
    className="flex flex-col items-center max-w-sm"
    onSubmit={(event) => {
      event.preventDefault();
      onSubmit();
    }}
  >
    <Logo className="-mt-6 mb-0" size={110} iconOnly />
    <h2 className="text-center mt-4 text-3xl font-inter">Account Login</h2>
    {fromPasswordReset ? (
      <div className="w-full bg-fuchsia-50 rounded-2xl p-6 mt-4">
        <p className="text-fuchsia-600 font-mediumi text-sm xs:text-base">
          Password successfully changed! Please log in with your new password.
        </p>
      </div>
    ) : (
      <p className="text-center text-sm sm:text-base text-slate-500/90 mt-3">
        Forgot your password, or too hard to type? Request a <em>magic link</em> with just
        your email address. Or,{` `}
        <Link
          className="text-violet-700 border-b border-dotted border-violet-700"
          to="/signup"
        >
          signup
        </Link>
        {` `}
        if you don&rsquo;t have an account yet.
      </p>
    )}
    <div className="self-stretch mt-5 sm:mt-7 space-y-3">
      <TextInput
        type="email"
        name="email"
        label="Email address:"
        placeholder="you@example.com"
        autoFocus={window.location.href.includes(`gertrude.app`)}
        required
        value={email}
        setValue={setEmail}
      />
      <TextInput
        type="password"
        name="password"
        label="Password:"
        required
        value={password}
        setValue={setPassword}
      />
    </div>
    <Link
      to="/reset-password"
      className="mb-6 mt-2 self-end text-violet-500 text-sm hover:text-violet-800 transition duration-100"
    >
      Forgot password?
    </Link>
    <div className="space-y-3 self-stretch">
      <Button color="primary" type="submit" fullWidth size="large">
        Submit &rarr;
      </Button>
      <Button
        testId="magic-link"
        disabled={email.match(/^.+@.+$/) === null}
        onClick={onSendMagicLink}
        color="secondary"
        type="button"
        fullWidth
        size="large"
      >
        Send Magic Link
      </Button>
    </div>
  </form>
);

export default LoginForm;
