import { Button } from '@shared/components';
import React, { useState } from 'react';
import AppHeader from './AppHeader';
import ResetPinModal from './ResetPinModal';

export type AmStatus = `active` | `approaching` | `paused`;

function amStatusLine(
  status: AmStatus,
  accessEndsAt?: string,
  trialDaysRemaining?: number,
): string {
  if (status === `paused`) {
    return `Paused — your Gertrude account needs Light or higher.`;
  }
  if (status === `approaching`) {
    return `Active — access ends ${accessEndsAt}.`;
  }
  if (trialDaysRemaining !== undefined) {
    return `Active — free trial, ${trialDaysRemaining} days remaining.`;
  }
  return `Active.`;
}

const AmDeviceSection: React.FC<{
  status: AmStatus;
  childName: string;
  deviceType: string;
  accessEndsAt?: string;
  trialDaysRemaining?: number;
  requestPinCode: () => Promise<number | null>;
}> = ({
  status,
  childName,
  deviceType,
  accessEndsAt,
  trialDaysRemaining,
  requestPinCode,
}) => {
  const [code, setCode] = useState<number | null>(null);
  const [isRequesting, setIsRequesting] = useState(false);
  const [error, setError] = useState<string | undefined>();

  const handleResetPin = async (): Promise<void> => {
    setError(undefined);
    setIsRequesting(true);
    const result = await requestPinCode();
    setIsRequesting(false);
    if (result === null) {
      setError(`Something went wrong generating a code. Please try again.`);
      return;
    }
    setCode(result);
  };

  return (
    <div className="max-w-3xl">
      <AppHeader app="podcasts" />
      <p className="mt-4 text-slate-500">
        {amStatusLine(status, accessEndsAt, trialDaysRemaining)}
      </p>
      <div className="mt-4">
        <Button
          type="button"
          color="secondary"
          onClick={() => void handleResetPin()}
          size="small"
          disabled={isRequesting}
        >
          <i className="fa-solid fa-key mr-2 text-xs" />
          {isRequesting ? `Generating…` : `Reset PIN`}
        </Button>
      </div>
      {error && <p className="mt-2 text-sm text-red-600">{error}</p>}
      <ResetPinModal
        isOpen={code !== null}
        onClose={() => setCode(null)}
        childName={childName}
        deviceType={deviceType}
        code={code ?? 0}
      />
    </div>
  );
};

export default AmDeviceSection;
