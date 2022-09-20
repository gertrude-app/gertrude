import React from 'react';
import { relativeTime } from '../../../lib/dates';
import TextInput from '../../../TextInput';
import Toggle from '../../../Toggle';
import KeyCreationStep from '../KeyCreationStep';
import GradientIcon from './GradientIcon';
import UserInputText from './UserInputText';

interface Props {
  mode: 'edit' | 'create';
  currentStepIndex: number;
  expiration?: Date;
}

function TitleText({ expiration }: { expiration: Date | undefined }): JSX.Element {
  return (
    <span>
      {expiration ? (
        <>
          Expiring <UserInputText>{relativeTime(expiration)}</UserInputText>
        </>
      ) : (
        <>
          With <UserInputText>no expiration</UserInputText>
        </>
      )}
    </span>
  );
}

const ExpirationStep: React.FC<Props> = ({ mode, currentStepIndex, expiration }) => (
  <KeyCreationStep
    mode={mode}
    setCurrentStep={() => {}}
    lookaheadTitle="Add an optional expiration"
    activeTitle="Add an optional expiration:"
    title={
      <h2 className="font-medium text-gray-900 text-lg">
        <GradientIcon icon="calendar" className="mr-2" />
        <TitleText expiration={expiration} />
      </h2>
    }
    currentStep={currentStepIndex}
    index={8}
  >
    <div className="flex justify-end mr-2 items-center">
      <label className="mr-2 text-gray-600">Expires:</label>
      <Toggle enabled={false} small setEnabled={() => {}} />
    </div>
    {expiration && (
      <div className="flex flex-col sm:flex-row mt-4">
        <TextInput
          type="date"
          value=""
          setValue={() => {}}
          label="Expiration date:"
          className="sm:mr-2 mb-4 sm:mb-0"
        />
        <TextInput
          type="time"
          value=""
          setValue={() => {}}
          label="Expiration time:"
          className="sm:ml-2"
        />
      </div>
    )}
  </KeyCreationStep>
);

export default ExpirationStep;
