import { Button } from '@shared/components';
import React from 'react';
import type { UnsuperviseCompleteProps } from '../types';
import InstructionLayout from '../InstructionLayout';
import NumberedSteps from '../NumberedSteps';

const UnsuperviseComplete: React.FC<UnsuperviseCompleteProps> = ({
  deviceType,
  onDone,
}) => (
  <InstructionLayout
    step={8}
    totalSteps={8}
    title="Supervision Removed"
    subtitle={`Your ${deviceType} is no longer supervised. You can disconnect the USB cable.`}
    footer={
      <Button type="button" onClick={onDone} color="gradient" size="large">
        Done, Quit
      </Button>
    }
  >
    <NumberedSteps
      steps={[
        {
          title: `Turn Find My back on`,
          subtitle: `Open Settings → your name → Find My → Find My ${deviceType}`,
        },
        {
          title: `Restore your Private Relay setting`,
          subtitle: `If it was on before, turn it back on in Settings → your name → iCloud`,
        },
        {
          title: `Delete this helper app`,
          subtitle: `Quit and delete Gertrude Unsupervisor from this computer when you’re done`,
        },
      ]}
    />
  </InstructionLayout>
);

export default UnsuperviseComplete;
