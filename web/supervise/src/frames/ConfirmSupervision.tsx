import { Button } from '@shared/components';
import React from 'react';
import type { ConfirmSupervisionProps } from '../types';
import InstructionLayout from '../InstructionLayout';
import NumberedSteps from '../NumberedSteps';
import confirmSupervisedImg from '../assets/confirm-supervised.png';

const img: any = confirmSupervisedImg;
const imgSrc: string = typeof img === `string` ? img : img.src;

const ConfirmSupervision: React.FC<ConfirmSupervisionProps> = ({ onYes, onNo }) => (
  <InstructionLayout
    step={8}
    totalSteps={8}
    title="Confirm Supervision"
    subtitle="Let’s verify that supervision was enabled successfully."
    imageSrc={imgSrc}
    imageAlt="Settings showing device is supervised"
    footer={
      <div className="flex gap-4">
        <Button type="button" onClick={onNo} color="secondary" size="large">
          No, it&rsquo;s not there
        </Button>
        <Button type="button" onClick={onYes} color="gradient" size="large">
          Yes, I see it &rarr;
        </Button>
      </div>
    }
  >
    <NumberedSteps
      steps={[
        {
          title: `Open the Settings app`,
          subtitle: `On the device you just supervised`,
        },
        {
          title: `Look at the top of the screen`,
          subtitle: `You should see “This iPhone is supervised and managed by Gertrude.”`,
        },
      ]}
    />
  </InstructionLayout>
);

export default ConfirmSupervision;
