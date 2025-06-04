import { FullscreenModalForm } from '@dash/components';
import { Button, Loading, Logo, TextInput } from '@shared/components';
import cx from 'classnames';
import React from 'react';
import Current from '../../environment';
import { useMutation } from '../../hooks';

const ConferenceEmailForm: React.FC<{ source: `workshop` | `booth` }> = ({ source }) => {
  const [email, setEmail] = React.useState(``);
  const [emailValid, setEmailValid] = React.useState(true);
  const submit = useMutation(() => Current.api.saveConferenceEmail({ email, source }));

  return (
    <FullscreenModalForm state="idle">
      <div className="flex flex-col items-center relative">
        <div className="flex items-center">
          <Logo className="" iconOnly size={75} />
          <div className="flex flex-col ml-3">
            <span className="text-4xl font-lato">
              <span className="text-slate-800">Gertrude</span>
            </span>
            <span className="bg-gradient-to-r from-indigo-500 to-fuchsia-600 bg-clip-text [-webkit-background-clip:text] text-transparent w-fit text-base uppercase font-semibold -mt-1 tracking-wide">
              Live at GHC 2025
            </span>
          </div>
        </div>
        <div className="flex flex-col justify-center items-center my-12">
          <div className="text-2xl font-bold">
            Thanks for {source === `workshop` ? `listening!` : `stopping by!`}
          </div>
          <p className="text-lg text-slate-500 text-center mt-3 relative">
            {source === `workshop`
              ? `Enter your email address to be notified when we release the talk online.`
              : `Enter your email address and we'll reach out soon to help you get started with Gertrude.`}
          </p>
        </div>
        {(submit.isIdle || submit.isError) && (
          <>
            <TextInput
              type="email"
              value={email}
              setValue={setEmail}
              autoFocus
              placeholder="you@example.com"
            />
            <Button
              type="button"
              onClick={() => {
                if (!/\S+@\S+\.\S+/.test(email)) {
                  setEmailValid(false);
                  return;
                }
                setEmailValid(true);
                submit.mutate(undefined);
              }}
              color="primary"
              size="large"
              className="self-stretch mt-4"
            >
              Submit <i className="fas fa-arrow-right ml-2" />
            </Button>
          </>
        )}
        {submit.isPending && <Loading className="mt-6" />}
        {!emailValid && submit.isIdle && (
          <Message
            heading="Invalid email address"
            message="Please enter a valid email address"
            success={false}
          />
        )}
        {submit.isError && (
          <Message
            success={false}
            heading="Uh oh!"
            message="Looks like something went wrong. Please refresh the page and try again."
          />
        )}
        {submit.isSuccess && (
          <Message
            success={true}
            heading="Success!"
            message="Expect to hear from us in a few days. Thanks for your interest!"
          />
        )}
      </div>
    </FullscreenModalForm>
  );
};

export default ConferenceEmailForm;

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
