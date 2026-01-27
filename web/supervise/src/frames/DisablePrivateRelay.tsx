import cx from 'classnames';
import React from 'react';
import type { DisablePrivateRelayProps } from '../types';

const DisablePrivateRelay: React.FC<DisablePrivateRelayProps> = ({ onContinue }) => (
  <div className="h-full flex flex-col items-center justify-center p-6 bg-white">
    <div className="w-12 h-12 mb-4 rounded-xl bg-purple-100 flex items-center justify-center">
      <svg
        className="w-6 h-6 text-purple-600"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
      >
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth={2}
          d="M8.111 16.404a5.5 5.5 0 017.778 0M12 20h.01m-7.08-7.071c3.904-3.905 10.236-3.905 14.141 0M1.394 9.393c5.857-5.857 15.355-5.857 21.213 0"
        />
      </svg>
    </div>

    <h1 className="text-lg font-semibold text-gray-900 mb-2">Turn Off Private Relay</h1>

    <p className="text-sm text-gray-600 text-center mb-4 max-w-[280px]">
      If you use iCloud Private Relay, please disable it temporarily. Go to{` `}
      <span className="font-medium">Settings → [Your Name] → iCloud → Private Relay</span>
      .
    </p>

    <p className="text-xs text-gray-400 text-center mb-6 max-w-[260px]">
      Skip this step if you don't use Private Relay.
    </p>

    <button
      onClick={onContinue}
      className={cx(
        `px-6 py-2.5 rounded-lg font-medium text-white transition-all`,
        `bg-gradient-to-r from-blue-500 to-indigo-600`,
        `hover:from-blue-600 hover:to-indigo-700`,
        `active:scale-[0.98]`,
      )}
    >
      Continue
    </button>
  </div>
);

export default DisablePrivateRelay;
