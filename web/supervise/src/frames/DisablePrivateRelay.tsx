import { Button } from '@shared/components';
import React from 'react';
import type { DisablePrivateRelayProps } from '../types';
import InstructionLayout from '../InstructionLayout';
import NumberedSteps from '../NumberedSteps';
import disablePrivateRelayImg from '../assets/disable-private-relay.png';

const img: any = disablePrivateRelayImg;
const imgSrc: string = typeof img === `string` ? img : img.src;

const DisablePrivateRelay: React.FC<DisablePrivateRelayProps> = ({ onContinue }) => (
  <InstructionLayout
    step={5}
    totalSteps={8}
    title="Turn Off Private Relay"
    subtitle="Private Relay if enabled blocks the supervision"
    imageSrc={imgSrc}
    imageAlt="Private Relay settings"
    footer={
      <Button type="button" onClick={onContinue} color="gradient" size="large">
        Continue &rarr;
      </Button>
    }
  >
    <div className="flex flex-col gap-6">
      <p className="text-slate-500">
        Private relay requires an iCloud+ subscription. If you don’t have one, or can’t
        find the setting, you can continue.
      </p>
      <NumberedSteps
        steps={[
          {
            title: `Open Settings`,
            subtitle: `Tap your name at the top of the screen`,
          },
          {
            title: <>Go to iCloud &rarr; Private Relay</>,
            subtitle: `Turn off Private Relay`,
          },
        ]}
      />
    </div>
  </InstructionLayout>
);

export default DisablePrivateRelay;
