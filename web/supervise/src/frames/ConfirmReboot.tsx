import cx from 'classnames';
import React from 'react';
import type { ConfirmRebootProps } from '../types';

const ConfirmReboot: React.FC<ConfirmRebootProps> = ({ onConfirm }) => (
  <div className="h-full flex flex-col items-center justify-center p-6 bg-white">
    <div className="w-12 h-12 mb-4 rounded-xl bg-blue-100 flex items-center justify-center">
      <svg
        className="w-6 h-6 text-blue-600"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
      >
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth={2}
          d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
        />
      </svg>
    </div>

    <h1 className="text-lg font-semibold text-gray-900 mb-2">Device Restarting</h1>

    <p className="text-sm text-gray-600 text-center mb-6 max-w-[280px]">
      Your device is restarting to apply changes. Wait for it to fully restart before
      continuing.
    </p>

    <button
      onClick={onConfirm}
      className={cx(
        `px-6 py-2.5 rounded-lg font-medium text-white transition-all`,
        `bg-gradient-to-r from-blue-500 to-indigo-600`,
        `hover:from-blue-600 hover:to-indigo-700`,
        `active:scale-[0.98]`,
      )}
    >
      Device has restarted
    </button>
  </div>
);

export default ConfirmReboot;
