import { posessive } from '@shared/string';
import React from 'react';
import type { PersonalizedConnectProps } from '../types';
import InstructionLayout from '../InstructionLayout';
import NumberedSteps from '../NumberedSteps';
import connectDeviceImg from '../assets/connect-device.png';

const img: any = connectDeviceImg;
const imgSrc: string = typeof img === `string` ? img : img.src;

const PersonalizedConnect: React.FC<PersonalizedConnectProps> = ({
  childName,
  deviceType,
  modelName,
  iosVersion,
}) => {
  const [showHint, setShowHint] = React.useState(false);

  React.useEffect(() => {
    const timer = setTimeout(() => setShowHint(true), 3 * 60 * 1000);
    return () => clearTimeout(timer);
  }, []);

  return (
    <InstructionLayout
      step={2}
      totalSteps={8}
      title={`Connect ${posessive(childName)} ${deviceType}`}
      subtitle={`${modelName} · iOS ${iosVersion}`}
      imageSrc={imgSrc}
      imageAlt="Connect device via USB"
      footer={
        <div className="flex items-center gap-3 text-violet-500">
          <svg className="w-5 h-5 animate-spin" fill="none" viewBox="0 0 24 24">
            <circle
              className="opacity-25"
              cx="12"
              cy="12"
              r="10"
              stroke="currentColor"
              strokeWidth="4"
            />
            <path
              className="opacity-75"
              fill="currentColor"
              d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
            />
          </svg>
          <span className="text-base font-medium">Waiting for USB connection...</span>
        </div>
      }
    >
      <NumberedSteps
        steps={[
          {
            title: `Plug in a USB cable`,
            subtitle: `Connect ${posessive(childName)} ${deviceType} to this computer`,
          },
          {
            title: `Tap "Trust" on the ${deviceType}`,
            subtitle: `A prompt will appear on the ${deviceType}'s screen`,
          },
        ]}
      />
      <div
        className={`mt-8 rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800 transition-opacity duration-700 ${showHint ? `opacity-100` : `opacity-0`}`}
      >
        <span className="font-medium">Trouble connecting?</span> Try a different cable,
        and make sure to plug <em>directly</em> into your computer—not through a dongle or
        adapter.
      </div>
    </InstructionLayout>
  );
};

export default PersonalizedConnect;
