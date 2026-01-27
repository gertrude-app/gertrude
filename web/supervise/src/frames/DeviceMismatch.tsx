import { Button } from '@shared/components';
import React from 'react';
import type { DeviceMismatchProps } from '../types';
import FrameBackground from '../FrameBackground';

const DeviceMismatch: React.FC<DeviceMismatchProps> = ({
  expectedModelName,
  connectedModelName,
  childName,
  onTryAgain,
}) => (
  <FrameBackground>
    <div className="flex flex-col items-center justify-center max-w-md">
      <div className="w-16 h-16 mb-6 rounded-2xl bg-red-100 flex items-center justify-center">
        <svg
          className="w-8 h-8 text-red-600"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
          />
        </svg>
      </div>

      <h1 className="text-2xl font-bold text-slate-800 mb-6">Wrong Device Connected</h1>

      <div className="bg-white rounded-xl border border-slate-200 p-5 mb-6 w-full">
        <div className="flex justify-between items-center mb-3 pb-3 border-b border-slate-100">
          <span className="text-sm text-slate-500">Expected</span>
          <span className="text-base font-semibold text-slate-800">
            {expectedModelName}
          </span>
        </div>
        <div className="flex justify-between items-center">
          <span className="text-sm text-slate-500">Connected</span>
          <span className="text-base font-semibold text-red-600">
            {connectedModelName}
          </span>
        </div>
      </div>

      <p className="text-base text-slate-600 text-center mb-8">
        Please disconnect this device and connect {childName}&rsquo;s {expectedModelName}.
      </p>

      <Button type="button" onClick={onTryAgain} color="gradient" size="large">
        Try Again
      </Button>
    </div>
  </FrameBackground>
);

export default DeviceMismatch;
