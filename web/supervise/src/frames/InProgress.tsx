import cx from 'classnames';
import React, { useState } from 'react';
import { useSupervise } from '../SuperviseContext';

const InProgress: React.FC = () => {
  const { api, mode, device, goToFrame, setError } = useSupervise();
  const [running, setRunning] = useState(false);
  const [progress, setProgress] = useState(0);

  const handleStart = async (): Promise<void> => {
    setRunning(true);
    setError(null);

    const progressInterval = setInterval(() => {
      setProgress((p) => Math.min(p + Math.random() * 15, 90));
    }, 500);

    try {
      await api.performOperation(mode);
      clearInterval(progressInterval);
      setProgress(100);
      setTimeout(() => goToFrame(`confirm-reboot`), 500);
    } catch (err) {
      clearInterval(progressInterval);
      const message = err instanceof Error ? err.message : `Operation failed`;
      if (message.toLowerCase().includes(`find my`)) {
        setError(`Find My iPhone is still enabled. Please disable it first.`);
        goToFrame(`disable-find-my`);
      } else {
        setError(message);
        setRunning(false);
        setProgress(0);
      }
    }
  };

  const actionText = mode === `add` ? `Supervise` : `Remove Supervision`;

  return (
    <div className="h-full flex flex-col items-center justify-center p-6 bg-white">
      <h1 className="text-lg font-semibold text-gray-900 mb-2">
        {running ? `Please wait...` : `Ready to ${actionText}`}
      </h1>

      <p className="text-sm text-gray-600 text-center mb-6 max-w-[280px]">
        {running
          ? `Do not disconnect your device.`
          : `Your device "${device?.name}" is ready. This will take about 30 seconds.`}
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
          onClick={handleStart}
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
