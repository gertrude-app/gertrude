import React from 'react';
import cx from 'classnames';
import FullscreenGradientBg from '../FullscreenGradientBg';
import Button from '../../Button';
import TextInput from '../TextInput';
import Logo from '../../Logo';
import Loading from '../../Loading';

type Props =
  | {
      state: `default`;
      title: string;
      subTitle: string;
      email: string;
      setEmail(email: string): unknown;
      onSubmit(): unknown;
    }
  | { state: `fetching` }
  | { state: `error`; error: string }
  | { state: `success`; message: string };

const EmailFormScreen: React.FC<Props> = (props) => {
  switch (props.state) {
    case `fetching`:
      return (
        <FullscreenGradientBg>
          <Loading />
        </FullscreenGradientBg>
      );

    case `success`:
    case `error`:
      return (
        <FullscreenGradientBg>
          <div
            className={cx(
              `bg-white font-sans rounded-2xl mx-4 px-10 py-6 shadow-lg flex items-center space-x-3`,
              props.state === `success` ? `text-green-800` : `text-red-600`,
            )}
          >
            <span role="img" aria-hidden className="text-4xl">
              {props.state === `success` ? `🎉 ` : `💩`}
            </span>
            <span>{props.state === `success` ? props.message : props.error}</span>
          </div>
        </FullscreenGradientBg>
      );
  }

  return (
    <FullscreenGradientBg>
      <form
        className="py-8 sm:py-12 px-5 sm:px-12 rounded-2xl shadow-lg flex justify-center items-center flex-col border bg-white relative z-10 mx-3 sm:mx-10"
        onSubmit={(event) => {
          event.preventDefault();
          props.onSubmit();
        }}
      >
        <Logo size={75} iconOnly />
        <h2 className="text-center mt-4 text-3xl font-inter">{props.title}</h2>
        <h3 className="text-center text-gray-500 mt-2">{props.subTitle}</h3>
        <TextInput
          type="email"
          label="Email address"
          className="mt-4 mb-6"
          placeholder="you@example.com"
          autoFocus
          required
          value={props.email}
          setValue={props.setEmail}
        />
        <Button color="primary-violet" type="submit" fullWidth>
          Submit &rarr;
        </Button>
      </form>
    </FullscreenGradientBg>
  );
};

export default EmailFormScreen;
