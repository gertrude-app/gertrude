import { Button, Logo, TextInput } from '@shared/components';
import React from 'react';

type Props = {
  id?: string;
  title: string;
  subTitle: React.ReactNode;
  email: string;
  setEmail(email: string): unknown;
  password?: string;
  setPassword?(password: string): unknown;
  onSubmit(): unknown;
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
}) => (
  <form
    id={id}
    className="flex flex-col items-center flex-grow"
    onSubmit={(event) => {
      event.preventDefault();
      onSubmit();
    }}
  >
    <Logo size={110} iconOnly className="-mt-6 mb-0" />
    <h2 className="text-center mt-4 text-3xl font-inter">{title}</h2>
    <h3 className="text-center text-slate-500 mt-3">{subTitle}</h3>
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
          label="Password:"
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
      Submit &rarr;
    </Button>
  </form>
);

export default EmailInputForm;
