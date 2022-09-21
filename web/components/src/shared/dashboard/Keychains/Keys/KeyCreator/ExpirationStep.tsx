import React from 'react';
import {
  relativeTime,
  isoToDateInput,
  formatDate,
  daysFromNow,
  isoToTimeInput,
  utcToLocal,
  isoToLocal,
} from '../../../lib/dates';
import TextInput from '../../../TextInput';
import Toggle from '../../../Toggle';
import KeyCreationStep from '../KeyCreationStep';
import GradientIcon from './GradientIcon';
import UserInputText from './UserInputText';

interface Props {
  mode: 'edit' | 'create';
  currentStepIndex: number;
  expiration?: string;
  update(event: EditKey.Event): unknown;
}

const ExpirationStep: React.FC<Props> = ({
  mode,
  update,
  currentStepIndex,
  expiration,
}) => (
  <KeyCreationStep
    update={update}
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
    <div className="flex justify-end mr-2 items-center -mt-3">
      <label className="mr-2 text-gray-600">Key expires</label>
      <Toggle
        enabled={!!expiration}
        small
        setEnabled={(enabled) =>
          update({
            set: `expirationDate`,
            to: enabled ? formatDate(utcToLocal(daysFromNow(7)), `dateInput`) : undefined,
          })
        }
      />
    </div>
    {expiration && (
      <div className="flex flex-col sm:flex-row">
        <TextInput
          type="date"
          value={isoToDateInput(isoToLocal(expiration))}
          setValue={(date) => update({ set: `expirationDate`, to: date })}
          label="Expiration date:"
          className="sm:mr-2 mb-4 sm:mb-0"
        />
        <TextInput
          type="time"
          value={isoToTimeInput(isoToLocal(expiration))}
          setValue={() => {}}
          label="Expiration time:"
          className="sm:ml-2"
        />
      </div>
    )}
  </KeyCreationStep>
);

export default ExpirationStep;

function TitleText({ expiration }: { expiration: string | undefined }): JSX.Element {
  return (
    <span>
      {expiration ? (
        <>
          Expiring <UserInputText>{relativeTime(new Date(expiration))}</UserInputText>
        </>
      ) : (
        <>
          With <UserInputText>no expiration</UserInputText>
        </>
      )}
    </span>
  );
}
