import { Button } from '@shared/components';
import React from 'react';
import InstructionLayout from '../InstructionLayout';
import NumberedSteps from '../NumberedSteps';
import connectDeviceImg from '../assets/connect-device.png';

const img: any = connectDeviceImg;
const imgSrc: string = typeof img === `string` ? img : img.src;

interface Props {
  deviceType: string;
  phase: string;
  onFinished?: () => void;
  onContactSupport: () => void;
  onBack?: () => void;
}

const FinishSetup: React.FC<Props> = ({
  deviceType,
  phase,
  onFinished,
  onContactSupport,
  onBack,
}) => {
  const needsHelp = [`uncertain`, `unreadable`].includes(phase);
  const checking = phase === `checking`;
  return (
    <InstructionLayout
      step={7}
      totalSteps={8}
      title={needsHelp ? `Let’s get some help` : `Finish setup on your ${deviceType}`}
      subtitle={needsHelp ? undefined : `This can take several minutes.`}
      imageSrc={imgSrc}
      imageAlt="Phone connected to a computer by USB"
      footer={
        <div className="flex gap-4">
          {onBack && (
            <Button type="button" color="secondary" onClick={onBack}>
              Back
            </Button>
          )}
          {(needsHelp || !onFinished) && (
            <Button type="button" color="secondary" onClick={onContactSupport}>
              Contact Support
            </Button>
          )}
          {!needsHelp && !checking && onFinished && (
            <Button type="button" color="gradient" size="large" onClick={onFinished}>
              I’m back at the Home Screen &rarr;
            </Button>
          )}
        </div>
      }
    >
      {needsHelp ? (
        <p className="text-slate-500">
          We couldn’t confirm how the restore finished. Contact Support before continuing.
          Don’t run supervision again.
        </p>
      ) : checking ? (
        <p role="status" className="text-slate-500">
          Checking your previous attempt…
        </p>
      ) : (
        <>
          <NumberedSteps
            steps={[
              { title: `Unlock your ${deviceType} after it restarts` },
              { title: `Swipe up or press Home to upgrade when prompted` },
              { title: `Tap Continue on “Restore Completed”` },
              {
                title: `Sign in with your Apple ID if asked`,
                subtitle: `Wait until you reach the Home Screen.`,
              },
            ]}
          />
          {phase === `restartFailed` && (
            <p role="status" className="mt-6 text-slate-500">
              Restart your {deviceType} manually, keeping the USB cable connected.
            </p>
          )}
          {!onFinished && (
            <p className="mt-6 text-slate-500">
              Once setup is finished, check for the supervision message at the top of
              Settings, then return to Gertrude. Contact Support if it’s missing.
            </p>
          )}
        </>
      )}
    </InstructionLayout>
  );
};

export default FinishSetup;
