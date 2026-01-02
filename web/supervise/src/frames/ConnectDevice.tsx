import cx from 'classnames';
import React, { useState } from 'react';
import { useSupervise } from '../SuperviseContext';

const ConnectDevice: React.FC = () => {
  const { api, setDevice, goToFrame, setError } = useSupervise();
  const [checking, setChecking] = useState(false);

  const handleConnect = async (): Promise<void> => {
    setChecking(true);
    setError(null);
    try {
      const device = await api.getConnectedDevice();
      setDevice(device);
      goToFrame(`choose-direction`);
    } catch (err) {
      setError(err instanceof Error ? err.message : `Failed to connect to device`);
    } finally {
      setChecking(false);
    }
  };

  return (
    <div className="h-full flex flex-col items-center justify-center p-6 bg-white">
      <div className="w-16 h-16 mb-4 rounded-2xl bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center">
        <svg
          className="w-8 h-8 text-white"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z"
          />
        </svg>
      </div>

      <h1 className="text-xl font-semibold text-gray-900 mb-2">Connect your device</h1>

      <p className="text-sm text-gray-600 text-center mb-6 max-w-[280px]">
        Connect your iOS device via USB cable and make sure it is unlocked and trusted.
      </p>

      <button
        onClick={handleConnect}
        disabled={checking}
        className={cx(
          `px-6 py-2.5 rounded-lg font-medium text-white transition-all`,
          `bg-gradient-to-r from-blue-500 to-indigo-600`,
          `hover:from-blue-600 hover:to-indigo-700`,
          `active:scale-[0.98]`,
          checking && `opacity-70 cursor-not-allowed`,
        )}
      >
        {checking ? `Checking...` : `Connect`}
      </button>
    </div>
  );
};

export default ConnectDevice;
