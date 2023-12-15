import React from 'react';
import cx from 'classnames';
import { FullscreenModalForm } from '@dash/components';
import { Button, Loading, Logo, TextInput } from '@shared/components';
import { useMutation } from '../../hooks';
import Current from '../../environment';

const HollandTalk: React.FC = () => {
  const [email, setEmail] = React.useState(``);
  const [emailValid, setEmailValid] = React.useState(true);
  const subscription = useMutation(() => Current.api.hollandTalkSubscription({ email }));

  return (
    <FullscreenModalForm state="idle">
      <div className="flex flex-col items-center relative">
        <div className="flex items-center">
          <Logo className="" iconOnly size={75} />
          <div className="flex flex-col ml-3">
            <span className="text-4xl font-lato">
              <span className="text-slate-800">Gertrude</span>
            </span>
            <span className="bg-gradient-to-r from-indigo-500 to-fuchsia-600 bg-clip-text [-webkit-background-clip:text] text-transparent w-fit text-base uppercase font-semibold -mt-1">
              Live in Holland, MI
            </span>
          </div>
        </div>
        <div className="flex flex-col justify-center items-center my-12">
          <div className="text-2xl font-bold">Thank you for attending!</div>
          <p className="text-lg text-slate-500 text-center mt-2 relative">
            Enter your email address to be notified when we release the talk online.
          </p>
          <div className="self-stretch flex justify-end pr-8">
            <span className="font-signature text-6xl -rotate-[20deg] text-fuchsia-500">
              -Jared
            </span>
          </div>
        </div>
        <TextInput
          type="email"
          value={email}
          setValue={setEmail}
          placeholder="me@example.com"
        />
        <Button
          type="button"
          onClick={() => {
            if (!/\S+@\S+\.\S+/.test(email)) {
              setEmailValid(false);
              return;
            }
            setEmailValid(true);
            subscription.mutate(undefined);
          }}
          color="primary"
          size="large"
          className="self-stretch mt-4"
        >
          Submit <i className="fas fa-arrow-right ml-2" />
        </Button>
        {subscription.isPending && <Loading className="mt-6" />}
        {!emailValid && subscription.isIdle && (
          <Message
            heading="Invalid email address"
            message="Please enter a valid email address"
            success={false}
          />
        )}
        {subscription.isError && (
          <Message
            success={false}
            heading="Uh oh!"
            message="Looks like something went wrong. Please refresh the page and try again."
          />
        )}
        {subscription.isSuccess && (
          <Message
            success={true}
            heading="Success!"
            message="We'll notify you as soon as we get the video ready."
          />
        )}
      </div>
    </FullscreenModalForm>
  );
};

export default HollandTalk;

const Message: React.FC<{ heading: string; message: string; success: boolean }> = ({
  heading,
  message,
  success,
}) => (
  <div
    className={cx(
      `mt-4 rounded-2xl p-4 self-stretch`,
      success ? `bg-green-100` : `bg-red-100`,
    )}
  >
    <h3 className={cx(`text-lg font-bold`, success ? `text-green-900` : `text-red-700`)}>
      {heading}
    </h3>
    <p
      className={cx(
        `text-sm mt-1 font-medium`,
        success ? `text-green-700` : `text-red-600`,
      )}
    >
      {message}
    </p>
  </div>
);
