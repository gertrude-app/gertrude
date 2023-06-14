import React, { useState } from 'react';
import cx from 'classnames';
import { Button, TextInput } from '@shared/components';
import FullscreenGradientBg from '@dash/components/src/Unauthed/FullscreenGradientBg';
import { GradientIcon } from '@dash/components';

const ResetPassword: React.FC = () => {
  const [email, setEmail] = useState('');
  const [page, setPage] = useState<'form' | 'confirmation'>('form');
  return (
    <FullscreenGradientBg>
      <div className="bg-white rounded-3xl shadow-xl z-10 mx-4 relative h-96 w-128 overflow-hidden">
        <div
          className={cx(
            'flex flex-col justify-between absolute [transition:300ms] h-full w-full top-0',
            page === `form` ? `left-0 opacity-100` : `-left-128 opacity-0`,
          )}
        >
          <div className="py-8 px-6 xs:px-8 flex flex-col items-center">
            <h1 className="text-3xl font-inter text-center">Reset your password</h1>
            <p className="text-slate-500 max-w-md mt-4 text-center">
              Enter your email address, and we'll send you a one-time link to reset your
              password.
            </p>
          </div>
          <div className="bg-slate-50 p-6 xs:p-8 rounded-b-3xl">
            <TextInput
              type="email"
              value={email}
              setValue={setEmail}
              placeholder="me@example.com"
            />
            <div className="flex flex-col xs:flex-row justify-between gap-4 mt-8">
              <Button type="link" color="tertiary" to="/login" className="flex-grow">
                Cancel
              </Button>
              <Button
                type="button"
                color="primary"
                onClick={() => setPage('confirmation')}
                className="flex-grow"
                disabled={email.split('@').length !== 2}
              >
                Send reset link
                <i className="fas fa-arrow-right ml-2" />
              </Button>
            </div>
          </div>
        </div>
        <div
          className={cx(
            'flex flex-col justify-center items-center absolute [transition:300ms] h-full w-full top-0 p-12',
            page === `form` ? `left-128 opacity-0` : `left-0 opacity-100`,
          )}
        >
          <GradientIcon icon="email" size="large" />
          <h2 className="font-inter text-3xl text-center mb-4 mt-6">Email sent!</h2>
          <p className="text-slate-500 max-w-[300px] text-center">
            Check your inbox for a link to create a new password.
          </p>
        </div>
      </div>
    </FullscreenGradientBg>
  );
};

export default ResetPassword;
