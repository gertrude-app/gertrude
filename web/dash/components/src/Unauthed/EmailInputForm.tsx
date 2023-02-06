import React from 'react';
import { Logo, TextInput, Button } from '@shared/components';

type Props = {
  title: string;
  subTitle: React.ReactNode;
  email: string;
  setEmail(email: string): unknown;
  password?: string;
  setPassword?(password: string): unknown;
  onSubmit(): unknown;
};

const EmailInputForm: React.FC<Props> = ({
  title,
  subTitle,
  email,
  setEmail,
  onSubmit,
  password,
  setPassword,
}) => (
  <form
    className="flex flex-col items-center flex-grow"
    onSubmit={(event) => {
      event.preventDefault();
      onSubmit();
    }}
  >
    <Logo size={90} iconOnly className="-mt-4 mb-2" />
    <h2 className="text-center mt-4 text-3xl font-inter">{title}</h2>
    <h3 className="text-center text-gray-500 mt-3">{subTitle}</h3>
    <div className="mt-4 space-y-4 mb-8 self-stretch">
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
      {setPassword && (
        <TextInput
          type="password"
          name="password"
          label="Password:"
          className="mb-6"
          required
          value={password ?? ``}
          setValue={setPassword}
        />
      )}
    </div>
    <Button color="primary" type="submit" fullWidth>
      Submit &rarr;
    </Button>
  </form>
);

export default EmailInputForm;
