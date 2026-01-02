import cx from 'classnames';
import React from 'react';
import { useSupervise } from '../SuperviseContext';

const DisableFindMy: React.FC = () => {
  const { goToFrame } = useSupervise();

  return (
    <div className="h-full flex flex-col items-center justify-center p-6 bg-white">
      <div className="w-12 h-12 mb-4 rounded-xl bg-orange-100 flex items-center justify-center">
        <svg
          className="w-6 h-6 text-orange-600"
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

      <h1 className="text-lg font-semibold text-gray-900 mb-2">Disable Find My iPhone</h1>

      <p className="text-sm text-gray-600 text-center mb-4 max-w-[280px]">
        Find My iPhone must be disabled before proceeding. Go to{` `}
        <span className="font-medium">Settings → [Your Name] → Find My</span>
        {` `}and turn it off.
      </p>

      <p className="text-xs text-gray-400 text-center mb-6 max-w-[260px]">
        You can re-enable it after the process is complete.
      </p>

      <button
        onClick={() => goToFrame(`disable-private-relay`)}
        className={cx(
          `px-6 py-2.5 rounded-lg font-medium text-white transition-all`,
          `bg-gradient-to-r from-blue-500 to-indigo-600`,
          `hover:from-blue-600 hover:to-indigo-700`,
          `active:scale-[0.98]`,
        )}
      >
        I've disabled it
      </button>
    </div>
  );
};

export default DisableFindMy;
