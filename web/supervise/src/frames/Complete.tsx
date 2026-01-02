import cx from 'classnames';
import React from 'react';
import { useSupervise } from '../SuperviseContext';

const Complete: React.FC = () => {
  const { api, mode, device } = useSupervise();

  const title = mode === `add` ? `Supervision Enabled` : `Supervision Removed`;
  const message =
    mode === `add`
      ? `"${device?.name}" is now supervised.`
      : `Supervision has been removed from "${device?.name}".`;

  return (
    <div className="h-full flex flex-col items-center justify-center p-6 bg-white">
      <div className="w-14 h-14 mb-4 rounded-full bg-green-100 flex items-center justify-center">
        <svg
          className="w-7 h-7 text-green-600"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M5 13l4 4L19 7"
          />
        </svg>
      </div>

      <h1 className="text-xl font-semibold text-gray-900 mb-2">{title}</h1>

      <p className="text-sm text-gray-600 text-center mb-6 max-w-[280px]">{message}</p>

      <button
        onClick={() => api.closeWindow()}
        className={cx(
          `px-6 py-2.5 rounded-lg font-medium text-white transition-all`,
          `bg-gradient-to-r from-green-500 to-emerald-600`,
          `hover:from-green-600 hover:to-emerald-700`,
          `active:scale-[0.98]`,
        )}
      >
        Done
      </button>
    </div>
  );
};

export default Complete;
