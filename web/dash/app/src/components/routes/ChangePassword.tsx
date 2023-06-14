import React, { useState } from 'react';
import { useParams } from 'react-router-dom';
import { EyeIcon, EyeSlashIcon } from '@heroicons/react/24/solid';
import FullscreenGradientBg from '@dash/components/src/Unauthed/FullscreenGradientBg';
import { Button, TextInput } from '@shared/components';

interface Props {}

const ChangePassword: React.FC<Props> = ({}) => {
  const { token } = useParams<{ token: UUID }>();
  const [password, setPassword] = useState('');
  const [passwordVisible, setPasswordVisible] = useState(false);
  return (
    <FullscreenGradientBg>
      <div className="bg-white rounded-3xl shadow-xl z-10 mx-4">
        <div className="px-6 xs:px-8 py-8">
          <h1 className="font-inter text-3xl text-center">Choose a new password</h1>
          <p className="text-slate-500 max-w-md mt-4 text-center">
            Enter a new password for your account, and we'll log you in.
          </p>
        </div>
        <div className="px-6 xs:px-8 py-8 bg-slate-50 rounded-b-3xl flex flex-col gap-8">
          <div className="flex justify-between items-center">
            <TextInput
              value={password}
              setValue={setPassword}
              type={passwordVisible ? 'text' : 'password'}
              className="flex-gro"
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
            onClick={() => {}}
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
