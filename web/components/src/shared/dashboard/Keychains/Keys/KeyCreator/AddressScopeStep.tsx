import React from 'react';
import SelectableListItem from '../../../SelectableListItem';
import Toggle from '../../../Toggle';
import KeyCreationStep from '../KeyCreationStep';
import GradientIcon from './GradientIcon';
import UserInputText from './UserInputText';

interface Props {
  mode: 'edit' | 'create';
  currentStepIndex: number;
  addressScope: 'webBrowsers' | 'unrestricted' | 'singleApp';
  showAdvancedAddressOptions: boolean;
  appIdentificationType: 'bundleId' | 'slug';
  apps: Array<{ slug: string; name: string }>;
}

const AddressScopeStep: React.FC<Props> = ({
  mode,
  currentStepIndex,
  showAdvancedAddressOptions,
  addressScope,
}) => {
  return (
    <KeyCreationStep
      mode={mode}
      setCurrentStep={() => {}}
      activeTitle="Select affected apps:"
      lookaheadTitle="Affected apps"
      title={
        <h2 className="font-medium text-gray-900 text-lg">
          <Title addressScope={addressScope} />
        </h2>
      }
      currentStep={currentStepIndex}
      index={3}
      canAdvance
    >
      <div>
        <h2 className="font-medium">Unlocked for:</h2>
        <div className="flex justify-end mr-2 items-center">
          <label className="mr-2 text-gray-600">Advanced:</label>
          <Toggle enabled={showAdvancedAddressOptions} small setEnabled={() => {}} />
        </div>
        <div className="mt-3 space-y-0.5">
          <SelectableListItem
            title={`Web browsers`}
            description={`Applies to all browsers, like Chrome, Safari, Firefox, etc.`}
            selected={addressScope === `webBrowsers`}
            onClick={() => {}}
            badges={[{ text: `Most common`, color: `green` }]}
          />
          <SelectableListItem
            title={`All apps`}
            description={`Permits access for every app (including browsers). Use for sites you're sure you trust.`}
            selected={addressScope === `unrestricted`}
            onClick={() => {}}
          />
          {showAdvancedAddressOptions && (
            <SelectableListItem
              title={`Single app`}
              description={`Unlock this site for one specific app you choose.`}
              selected={addressScope === `singleApp`}
              onClick={() => {}}
            />
          )}
        </div>
      </div>
    </KeyCreationStep>
  );
};

export default AddressScopeStep;

const Title: React.FC<{
  addressScope: 'webBrowsers' | 'unrestricted' | 'singleApp';
}> = ({ addressScope }) => {
  switch (addressScope) {
    case `webBrowsers`:
      return (
        <>
          <GradientIcon icon="google-chrome" className="mr-2" />
          For <UserInputText>all web browsers</UserInputText>
        </>
      );
    case `unrestricted`:
      return (
        <>
          <GradientIcon icon="lightning-bolt" className="mr-2" />
          For <UserInputText>all apps</UserInputText>
        </>
      );
    case `singleApp`:
      return (
        <>
          <GradientIcon icon="location" className="mr-2" />
          For <UserInputText>a single app</UserInputText>
        </>
      );
  }
};
