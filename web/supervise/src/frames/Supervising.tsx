import { ProgressIndicator } from '@shared/components';
import React from 'react';
import type { SupervisingProps } from '../types';
import FrameBackground from '../FrameBackground';

const Supervising: React.FC<SupervisingProps> = ({ deviceType }) => (
  <FrameBackground>
    <div className="absolute top-0 left-0 w-full p-5 flex justify-center">
      <ProgressIndicator step={6} totalSteps={8} />
    </div>
    <div className="w-full h-full flex flex-col items-center justify-center px-10 py-10">
      <div className="flex flex-col items-center gap-8">
        <div className="w-20 h-20 flex items-center justify-center">
          <svg
            className="w-16 h-16 text-violet-500 animate-spin"
            fill="none"
            viewBox="0 0 24 24"
          >
            <circle
              className="opacity-25"
              cx="12"
              cy="12"
              r="10"
              stroke="currentColor"
              strokeWidth="4"
            />
            <path
              className="opacity-75"
              fill="currentColor"
              d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
            />
          </svg>
        </div>

        <div className="text-center">
          <h1 className="text-3xl font-bold text-slate-800 mb-3">Please Wait</h1>
          <p className="text-slate-500 text-lg">Do not disconnect your {deviceType}.</p>
        </div>
      </div>
    </div>
  </FrameBackground>
);

export default Supervising;
