import React from 'react';
import Button from '../../../Button';
import TextInput from '../../TextInput';
import Logo from '../../../Logo';

type Props = {
  title: string;
  subTitle: string;
  email: string;
  setEmail(email: string): unknown;
  onSubmit(): unknown;
};

const EmailInputForm: React.FC<Props> = ({
  title,
  subTitle,
  email,
  setEmail,
  onSubmit,
}) => (
  <form
    className="flex flex-col items-center space-x-3"
    onSubmit={(event) => {
      event.preventDefault();
      onSubmit();
    }}
  >
    <Logo size={75} iconOnly />
    <h2 className="text-center mt-4 text-3xl font-inter">{title}</h2>
    <h3 className="text-center text-gray-500 mt-2">{subTitle}</h3>
    <TextInput
      type="email"
      label="Email address"
      className="mt-4 mb-6"
      placeholder="you@example.com"
      autoFocus={window.location.href.includes(`gertrude.app`)}
      required
      value={email}
      setValue={setEmail}
    />
    <Button color="primary-violet" type="submit" fullWidth>
      Submit &rarr;
    </Button>
  </form>
);

export default EmailInputForm;
