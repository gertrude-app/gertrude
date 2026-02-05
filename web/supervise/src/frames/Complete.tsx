import { Button } from '@shared/components';
import { posessive } from '@shared/string';
import React from 'react';
import type { CompleteProps } from '../types';
import InstructionLayout from '../InstructionLayout';
import NumberedSteps from '../NumberedSteps';
import gertrudeAppImg from '../assets/gertrude-app.png';

const img: any = gertrudeAppImg;
const gertrudeAppSrc: string = typeof img === `string` ? img : img.src;

const Complete: React.FC<CompleteProps> = ({ childName, deviceType, onDone }) => (
  <InstructionLayout
    step={8}
    totalSteps={8}
    title="Supervision Complete!"
    subtitle={`Just one more step to do on the Gertrude app to enable blocking`}
    imageSrc={gertrudeAppSrc}
    imageAlt="Gertrude app"
    footer={
      <Button type="button" onClick={onDone} color="gradient" size="large">
        Done
      </Button>
    }
  >
    <NumberedSteps
      steps={[
        {
          title: `Launch Gertrude on ${posessive(childName)} ${deviceType}`,
          subtitle: `The app will know that supervision is complete`,
        },
        {
          title: `Follow the instructions to finish setup`,
          subtitle: `You will be guided to download a profile`,
        },
      ]}
    />
    <p className="mt-12 text-sm text-slate-500">
      Don't forget to re-enable Find My and Private Relay.
    </p>
  </InstructionLayout>
);

export default Complete;
