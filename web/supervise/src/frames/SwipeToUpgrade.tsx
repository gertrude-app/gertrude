import { Button } from '@shared/components';
import React from 'react';
import type { SwipeToUpgradeProps } from '../types';
import InstructionLayout from '../InstructionLayout';
import NumberedSteps from '../NumberedSteps';
import swipeUpgradeImg from '../assets/swipe-upgrade.png';

const img: any = swipeUpgradeImg;
const imgSrc: string = typeof img === `string` ? img : img.src;

const SwipeToUpgrade: React.FC<SwipeToUpgradeProps> = ({ onContinue }) => (
  <InstructionLayout
    step={7}
    totalSteps={8}
    title="Confirm Upgrade"
    subtitle="This part takes about 2-3 minutes, the device will appear to restart several times."
    imageSrc={imgSrc}
    imageAlt="iOS upgrade confirmation screen"
    footer={
      <Button type="button" onClick={onContinue} color="gradient" size="large">
        Done, restarted &rarr;
      </Button>
    }
  >
    <NumberedSteps
      steps={[
        {
          title: `The device will go black, then white`,
          subtitle: `This is normal during the supervision process`,
        },
        {
          title: `Swipe up to confirm when prompted`,
          subtitle: `Enter passcode, screen will stay white`,
        },
        {
          title: `Wait for final restart`,
          subtitle: `You may see a brief “Hello” screen`,
        },
      ]}
    />
  </InstructionLayout>
);

export default SwipeToUpgrade;
