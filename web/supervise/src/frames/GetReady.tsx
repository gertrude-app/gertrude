import { Button } from '@shared/components';
import React from 'react';
import type { GetReadyProps } from '../types';
import InstructionLayout from '../InstructionLayout';
import NumberedSteps from '../NumberedSteps';
import appleProgressImg from '../assets/apple-progress.png';

const img: any = appleProgressImg;
const imgSrc: string = typeof img === `string` ? img : img.src;

const GetReady: React.FC<GetReadyProps> = ({ onStart }) => (
  <InstructionLayout
    step={6}
    totalSteps={8}
    title="Get Ready"
    subtitle="Your device will reboot, and you may need to enter the passcode to continue."
    imageSrc={imgSrc}
    imageAlt="Device showing progress bar"
    footer={
      <Button type="button" onClick={onStart} color="gradient" size="large">
        Enable Supervised Mode &rarr;
      </Button>
    }
  >
    <NumberedSteps
      variant="checkmark"
      steps={[
        {
          title: `No data will be lost`,
          subtitle: `Your apps, photos, and settings will remain intact`,
        },
        {
          title: `Keep the device connected`,
          subtitle: `Don't unplug the USB cable during the process`,
        },
      ]}
    />
  </InstructionLayout>
);

export default GetReady;
