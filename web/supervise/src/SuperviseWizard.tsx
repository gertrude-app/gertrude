import React, { useState } from 'react';
import type { DeviceInfo, Frame, OperationMode, SuperviseApi } from './types';
import SuperviseContext from './SuperviseContext';
import * as Frames from './frames';

interface Props {
  api: SuperviseApi;
  initialFrame?: Frame;
  initialDevice?: DeviceInfo | null;
  initialMode?: OperationMode;
  initialError?: string | null;
}

const SuperviseWizard: React.FC<Props> = ({
  api,
  initialFrame = `connect-device`,
  initialDevice = null,
  initialMode = `add`,
  initialError = null,
}) => {
  const [currentFrame, setCurrentFrame] = useState<Frame>(initialFrame);
  const [device, setDevice] = useState<DeviceInfo | null>(initialDevice);
  const [mode, setMode] = useState<OperationMode>(initialMode);
  const [error, setError] = useState<string | null>(initialError);

  const renderFrame = (): React.ReactNode => {
    switch (currentFrame) {
      case `connect-device`:
        return <Frames.ConnectDevice />;
      case `choose-direction`:
        return <Frames.ChooseDirection />;
      case `disable-find-my`:
        return <Frames.DisableFindMy />;
      case `disable-private-relay`:
        return <Frames.DisablePrivateRelay />;
      case `in-progress`:
        return <Frames.InProgress />;
      case `confirm-reboot`:
        return <Frames.ConfirmReboot />;
      case `complete`:
        return <Frames.Complete />;
    }
  };

  return (
    <SuperviseContext.Provider
      value={{
        api,
        device,
        setDevice,
        mode,
        setMode,
        currentFrame,
        goToFrame: setCurrentFrame,
        error,
        setError,
      }}
    >
      <div className="w-[400px] h-[350px] overflow-hidden bg-white rounded-lg shadow-lg">
        {error && (
          <div className="absolute top-0 left-0 right-0 bg-red-500 text-white text-xs px-3 py-1.5 text-center">
            {error}
          </div>
        )}
        {renderFrame()}
      </div>
    </SuperviseContext.Provider>
  );
};

export default SuperviseWizard;
