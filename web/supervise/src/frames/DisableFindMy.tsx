import { Button } from '@shared/components';
import { posessive } from '@shared/string';
import React from 'react';
import type { DisableFindMyProps } from '../types';
import InstructionLayout from '../InstructionLayout';
import NumberedSteps from '../NumberedSteps';
import disableFindMyIpadImg from '../assets/disable-findmy-ipad.png';
import disableFindMyIphoneImg from '../assets/disable-findmy-iphone.png';

const iphoneImg: any = disableFindMyIphoneImg;
const ipadImg: any = disableFindMyIpadImg;
const iphoneSrc: string = typeof iphoneImg === `string` ? iphoneImg : iphoneImg.src;
const ipadSrc: string = typeof ipadImg === `string` ? ipadImg : ipadImg.src;

const DisableFindMy: React.FC<DisableFindMyProps> = ({
  childName,
  deviceType,
  onContinue,
}) => (
  <InstructionLayout
    step={4}
    totalSteps={8}
    title={`Temporarily Disable Find My ${deviceType}`}
    subtitle="You can re-enable it after supervision is complete."
    imageSrc={deviceType === `iPad` ? ipadSrc : iphoneSrc}
    imageAlt={`Find My ${deviceType} settings`}
    footer={
      <Button type="button" onClick={onContinue} color="gradient" size="large">
        Done, next &rarr;
      </Button>
    }
  >
    <NumberedSteps
      steps={[
        {
          title: `Open the Settings App`,
          subtitle: `To the main, outermost screen`,
        },
        {
          title: `Tap ${posessive(childName)} name at the top`,
          subtitle: `This leads to the Apple Account settings`,
        },
        {
          title: <>Go to Find My &rarr; Find My {deviceType}</>,
          subtitle: <>Turn off Find My {deviceType}</>,
        },
      ]}
    />
    <p className="mt-8 text-sm text-gray-500">
      You may have to disable <em>Stolen Device Protection</em> in order to do this.
    </p>
  </InstructionLayout>
);

export default DisableFindMy;
