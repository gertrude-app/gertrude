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
    title="Almost Done!"
    subtitle={`Just one more step to do back on the Gertrude app to enable blocking`}
    imageSrc={gertrudeAppSrc}
    imageAlt="Gertrude app"
    footer={
      <Button type="button" onClick={onDone} color="gradient" size="large">
        Profile Installed, Quit
      </Button>
    }
  >
    <NumberedSteps
      steps={[
        {
          title: `Launch Gertrude back on ${posessive(childName)} ${deviceType}`,
          subtitle: `The app will guide you through the final steps`,
        },
        {
          title: `Follow the instructions to finish setup`,
          subtitle: `You will be guided to download a profile`,
        },
        {
          title: `Delete this helper app`,
          subtitle: `Once the profile is installed, quit and delete this app, you won’t need it again!`,
        },
      ]}
    />
    <p className="mt-12 text-sm text-slate-500">
      Don’t forget to re-enable Find My and Private Relay.
    </p>
  </InstructionLayout>
);

export default Complete;
