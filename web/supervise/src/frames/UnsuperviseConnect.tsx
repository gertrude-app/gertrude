import React from 'react';
import type { UnsuperviseConnectProps } from '../types';
import InstructionLayout from '../InstructionLayout';
import NumberedSteps from '../NumberedSteps';
import connectDeviceImg from '../assets/connect-device.png';

const img: any = connectDeviceImg;
const imgSrc: string = typeof img === `string` ? img : img.src;

const UnsuperviseConnect: React.FC<UnsuperviseConnectProps> = ({ isWindows }) => (
  <InstructionLayout
    step={2}
    totalSteps={8}
    title="Remove Gertrude Supervision"
    subtitle="Connect the iPhone or iPad you want to remove supervision from."
    imageSrc={imgSrc}
    imageAlt="Connect device via USB"
    footer={
      <p role="status" className="text-base font-medium text-violet-500">
        Waiting for USB connection...
      </p>
    }
  >
    <NumberedSteps
      steps={[
        {
          title: `Plug in a USB cable`,
          subtitle: `Connect only the device you want to unsupervise`,
        },
        {
          title: `Unlock the device`,
          subtitle: `Tap “Trust” if prompted, and enter your passcode`,
        },
      ]}
    />
    <p className="mt-8 text-sm text-slate-500">
      Trouble connecting? Try a different cable and plug directly into your computer.
      {isWindows && ` Make sure iTunes has been installed and opened at least once.`}
    </p>
  </InstructionLayout>
);

export default UnsuperviseConnect;
