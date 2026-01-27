import cx from 'classnames';
import React from 'react';
import type { InProgressProps } from '../types';

const InProgress: React.FC<InProgressProps> = ({
  mode,
  deviceName,
  running,
  progress,
  onStart,
}) => {
  const actionText = mode === `add` ? `Supervise` : `Remove Supervision`;

  return (
    <div className="h-full flex flex-col items-center justify-center p-6 bg-white">
      <h1 className="text-lg font-semibold text-gray-900 mb-2">
        {running ? `Please wait...` : `Ready to ${actionText}`}
      </h1>

      <p className="text-sm text-gray-600 text-center mb-6 max-w-[280px]">
        {running
          ? `Do not disconnect your device.`
          : `Your device "${deviceName}" is ready. This will take about 30 seconds.`}
      </p>

      {running ? (
        <div className="w-full max-w-[280px]">
          <div className="h-2 bg-gray-200 rounded-full overflow-hidden">
            <div
              className="h-full bg-gradient-to-r from-blue-500 to-indigo-600 transition-all duration-300"
              style={{ width: `${progress}%` }}
            />
          </div>
          <p className="text-xs text-gray-400 text-center mt-2">
            {Math.round(progress)}%
          </p>
        </div>
      ) : (
        <button
          onClick={onStart}
          className={cx(
            `px-6 py-2.5 rounded-lg font-medium text-white transition-all`,
            `bg-gradient-to-r from-blue-500 to-indigo-600`,
            `hover:from-blue-600 hover:to-indigo-700`,
            `active:scale-[0.98]`,
          )}
        >
          {actionText} Now
        </button>
      )}
    </div>
  );
};

export default InProgress;
