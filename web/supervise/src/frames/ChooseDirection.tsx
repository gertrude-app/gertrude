import cx from 'classnames';
import React from 'react';
import { useSupervise } from '../SuperviseContext';

const ChooseDirection: React.FC = () => {
  const { device, setMode, goToFrame } = useSupervise();

  const handleChoice = (mode: `add` | `remove`): void => {
    setMode(mode);
    goToFrame(`disable-find-my`);
  };

  return (
    <div className="h-full flex flex-col items-center justify-center p-6 bg-white">
      <p className="text-sm text-gray-500 mb-1">Connected to</p>
      <p className="text-lg font-medium text-gray-900">{device?.name ?? `Device`}</p>
      <p className="text-xs text-gray-400 mb-6">
        {device?.model} · iOS {device?.osVersion}
      </p>

      <p className="text-sm text-gray-600 mb-4">What would you like to do?</p>

      <div className="flex flex-col gap-3 w-full max-w-[280px]">
        <button
          onClick={() => handleChoice(`add`)}
          className={cx(
            `w-full px-4 py-3 rounded-lg text-left transition-all`,
            `bg-gradient-to-r from-blue-500 to-indigo-600 text-white`,
            `hover:from-blue-600 hover:to-indigo-700`,
            `active:scale-[0.98]`,
          )}
        >
          <span className="font-medium">Supervise device</span>
          <span className="block text-xs text-white/70 mt-0.5">
            Enable supervision on this device
          </span>
        </button>

        <button
          onClick={() => handleChoice(`remove`)}
          className={cx(
            `w-full px-4 py-3 rounded-lg text-left transition-all`,
            `bg-gray-100 text-gray-900`,
            `hover:bg-gray-200`,
            `active:scale-[0.98]`,
          )}
        >
          <span className="font-medium">Remove supervision</span>
          <span className="block text-xs text-gray-500 mt-0.5">
            Remove existing supervision
          </span>
        </button>
      </div>
    </div>
  );
};

export default ChooseDirection;
