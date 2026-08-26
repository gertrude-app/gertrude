import { Button, TextInput } from '@shared/components';
import React from 'react';
import Logo from '../Logo';

type Props = {
  id?: string;
  title: string;
  subTitle: React.ReactNode;
  email: string;
  setEmail(email: string): unknown;
  password?: string;
  setPassword?(password: string): unknown;
  onSubmit(): unknown;
  beforeInputs?: React.ReactNode;
};

const EmailInputForm: React.FC<Props> = ({
  id,
  title,
  subTitle,
  email,
  setEmail,
  onSubmit,
  password,
  setPassword,
  beforeInputs,
}) => (
  <form
    id={id}
    className="flex flex-col items-center flex-grow"
    onSubmit={(event) => {
      event.preventDefault();
      onSubmit();
    }}
  >
    <Logo size={84} iconOnly className="-mt-4 mb-0" />
    <h2 className="text-center mt-4 text-3xl font-inter">{title}</h2>
    <h3 className="text-center text-slate-500 mt-3">{subTitle}</h3>
    {beforeInputs && <div className="mt-4 self-stretch">{beforeInputs}</div>}
    <div className="mt-4 space-y-4 mb-8 self-stretch">
      <TextInput
        type="email"
        name="email"
        label="Email address:"
        placeholder="you@example.com"
        autoFocus={window.location.href.includes(`gertrude.app`)}
        autoComplete="username"
        required
        value={email}
        setValue={setEmail}
      />
      {setPassword && (
        <TextInput
          type="password"
          name="password"
          label="Create a password:"
          className="mb-6"
          autoComplete="new-password"
          required
          value={password ?? ``}
          setValue={setPassword}
        />
      )}
    </div>
    <Button
      id={id ? `${id}--submit` : undefined}
      color="primary"
      type="submit"
      fullWidth
      size="large"
    >
      Signup &rarr;
    </Button>
    <p className="mt-4 text-xs text-center text-slate-400">
      By signing up, you agree to our{` `}
      <a
        className="text-slate-500 underline decoration-dotted underline-offset-2"
        href="https://gertrude.app/legal/terms"
        target="_blank"
        rel="noreferrer"
      >
        terms of service
      </a>
      .
    </p>
  </form>
);

export default EmailInputForm;
