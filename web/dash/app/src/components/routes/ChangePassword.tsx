import React, { useState } from 'react';
import { Link, Navigate, useParams } from 'react-router-dom';
import { EyeIcon, EyeSlashIcon } from '@heroicons/react/24/solid';
import { FullscreenGradientBg } from '@dash/components';
import { Button, TextInput } from '@shared/components';
import { ErrorMessage } from '@dash/components';
import { useMutation } from '../../hooks';
import Current from '../../environment';

const ChangePassword: React.FC = () => {
  const { token = `` } = useParams<{ token: UUID }>();
  const [password, setPassword] = useState(``);
  const [passwordVisible, setPasswordVisible] = useState(false);
  const resetPassword = useMutation((data: { token: string; password: string }) =>
    Current.api.resetPassword({ ...data }),
  );

  if (resetPassword.data && resetPassword.data.success) {
    return <Navigate to={`/login?from=reset`} replace />;
  }

  return (
    <FullscreenGradientBg>
      <div className="bg-white rounded-2xl shadow-xl z-10 mx-4">
        <div className="px-6 xs:px-8 py-8 flex flex-col items-center">
          <h1 className="font-inter text-3xl text-center">Choose a new password</h1>
          <p className="text-slate-500 max-w-md mt-4 text-center">
            Enter a new password for your account, and we'll redirect you back to the
            login screen.
          </p>
          {resetPassword.isError && (
            <ErrorMessage className="mt-6">
              {resetPassword.error.userMessage ?? `Hmm, something went wrong.`}
            </ErrorMessage>
          )}
          {resetPassword.data && !resetPassword.data.success && (
            <ErrorMessage className="mt-6 max-w-md">
              Token expired or not found. Please request a{` `}
              <Link to="/reset-password" className="underline hover:text-red-700">
                new password reset link.
              </Link>
            </ErrorMessage>
          )}
        </div>
        <div className="px-6 xs:px-8 py-8 bg-slate-50 rounded-b-3xl flex flex-col gap-8">
          <div className="flex justify-between items-center">
            <TextInput
              value={password}
              setValue={setPassword}
              type={passwordVisible ? `text` : `password`}
            />
            <button
              className="ml-4 rounded-full w-10 h-10 shrink-0 flex justify-center items-center text-slate-300 hover:text-slate-500 hover:bg-slate-100 transition duration-200"
              onClick={() => setPasswordVisible(!passwordVisible)}
            >
              {passwordVisible ? (
                <EyeSlashIcon className="h-6" />
              ) : (
                <EyeIcon className="h-6" />
              )}
            </button>
          </div>
          <Button
            type="button"
            color="primary"
            onClick={() => resetPassword.mutate({ token, password })}
            className="flex-grow"
            disabled={password.length <= 4}
          >
            Log in
            <i className="fas fa-arrow-right ml-2" />
          </Button>
        </div>
      </div>
    </FullscreenGradientBg>
  );
};

export default ChangePassword;
