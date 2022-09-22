import React from 'react';
import SelectableListItem from '../../../SelectableListItem';
import Toggle from '../../../Toggle';
import KeyCreationStep from './KeyCreationStep';
import GradientIcon from './GradientIcon';
import UserInputText from './UserInputText';
import * as EditKey from '../../../lib/keys/edit';

interface Props {
  mode: 'edit' | 'create';
  activeStep: EditKey.Step;
  addressScope: 'webBrowsers' | 'unrestricted' | 'singleApp';
  showAdvancedAddressScopeOptions: boolean;
  appIdentificationType: 'bundleId' | 'slug';
  apps: Array<{ slug: string; name: string }>;
  update(event: EditKey.Event): unknown;
}

const WebsiteKeyAppScopeStep: React.FC<Props> = ({
  mode,
  activeStep,
  showAdvancedAddressScopeOptions,
  addressScope,
  update,
}) => {
  return (
    <KeyCreationStep
      mode={mode}
      update={update}
      setCurrentStep={() => {}}
      activeTitle="Select affected apps:"
      lookaheadTitle="Affected apps"
      title={
        <h2 className="font-medium text-gray-900 text-lg">
          <Title addressScope={addressScope} />
        </h2>
      }
      activeStep={activeStep}
      ownStep={EditKey.Step.WebsiteKey_SetAppScope}
      canAdvance
    >
      <div>
        <h2 className="font-medium">Unlocked for:</h2>
        <div className="flex justify-end mr-2 items-center">
          <label className="mr-2 text-gray-600">Advanced:</label>
          <Toggle
            enabled={showAdvancedAddressScopeOptions}
            small
            setEnabled={(enabled) =>
              update({ type: `setShowAdvancedAddressScopeOptions`, to: enabled })
            }
          />
        </div>
        <div className="mt-3 space-y-0.5">
          <SelectableListItem
            title={`Web browsers`}
            description={`Applies to all browsers, like Chrome, Safari, Firefox, etc.`}
            selected={addressScope === `webBrowsers`}
            onClick={() => update({ type: `setAddressScope`, to: `webBrowsers` })}
            badges={[{ text: `Most common`, color: `green` }]}
          />
          <SelectableListItem
            title="All apps"
            description="Permits access for every app (including browsers). Use for sites you're sure you trust."
            selected={addressScope === `unrestricted`}
            onClick={() => update({ type: `setAddressScope`, to: `unrestricted` })}
          />
          {showAdvancedAddressScopeOptions && (
            <SelectableListItem
              title="Single app"
              description="Unlock this site for one specific app you choose."
              selected={addressScope === `singleApp`}
              onClick={() => update({ type: `setAddressScope`, to: `singleApp` })}
              badges={[
                { text: `Most safe`, color: `green` },
                { text: `Advanced`, color: `yellow` },
              ]}
            />
          )}
        </div>
      </div>
    </KeyCreationStep>
  );
};

export default WebsiteKeyAppScopeStep;

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
