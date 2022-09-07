import React, { useCallback, useEffect, useState } from 'react';
import KeyCreationStep from '../KeyCreationStep';
import cx from 'classnames';
import KeyTypeOption from '../KeyTypeOption';
import TextInput from '../TextInput';
import Toggle from '../Toggle';
import SelectMenu from '../SelectMenu';
import { capitalize } from '../../lib/string';
import KeyScopeRadioOption from '../KeyScopeRadioOption';
import Combobox, { ComboboxOption } from '../Combobox/Combobox';

interface Props {
  mode: 'create' | 'edit';
}

const KeyCreator: React.FC<Props> = ({ mode }) => {
  const [currentStep, setCurrentStep] = useState(1);
  const [keyType, setKeyType] = useState<'website' | 'app'>(`website`);
  const [addressType, setAddressType] = useState<
    'standard' | 'strict' | 'regular expression' | 'IP address'
  >(`standard`);
  const [address, setAddress] = useState(``);
  const [advancedAddressOptions, setAdvancedAddressOptions] = useState(false);
  const [keyScope, setKeyScope] = useState<'web browsers' | 'all apps' | 'single app'>(
    `web browsers`,
  );
  const [selectedApp, setSelectedApp] = useState<ComboboxOption>({ name: ``, id: `` });

  const commonApplications: ComboboxOption[] = [
    { name: `Slack`, id: `app-1` },
    { name: `Chrome`, id: `app-2` },
    { name: `Figma`, id: `app-3` },
    { name: `Notes`, id: `app-4` },
    { name: `Firefox`, id: `app-5` },
    { name: `VSCode`, id: `app-6` },
    { name: `Skype`, id: `app-7` },
    { name: `Sketch`, id: `app-8` },
    { name: `Photoshop`, id: `app-9` },
    { name: `Safari`, id: `app-10` },
    { name: `Calendar`, id: `app-11` },
    { name: `Brave`, id: `app-12` },
    { name: `Edge`, id: `app-13` },
    { name: `MatLab`, id: `app-14` },
    { name: `Microsoft Teams`, id: `app-15` },
  ];

  return (
    <div className="">
      <KeyCreationStep
        mode={mode}
        setCurrentStep={setCurrentStep}
        stepName="Select key type"
        numSteps={5}
        title={
          <h1 className="font-medium text-gray-900 text-lg">
            <i
              className={cx(
                `fa-solid mr-2 bg-gradient-to-br from-indigo-500 to-fuchsia-500 bg-clip-text [-webkit-background-clip:text;] text-transparent`,
                keyType === `website` ? `fa-earth-americas` : `fa-hamburger`,
              )}
            />
            <span className="capitalize">{keyType}</span> key
          </h1>
        }
        currentStep={currentStep}
        index={1}
      >
        <div className="flex flex-col sm:flex-row">
          <KeyTypeOption
            icon={`earth-americas`}
            selected={keyType === `website`}
            onClick={() => setKeyType(`website`)}
            title="Website key"
            description="Grant access to a specific website"
            className="sm:w-1/2 sm:mr-2 mb-3 sm:mb-0"
          />
          <KeyTypeOption
            icon={`hamburger`}
            selected={keyType === `app`}
            onClick={() => setKeyType(`app`)}
            title="App key"
            description="Grant access to a specific mac application"
            className="sm:w-1/2 sm:ml-2"
          />
        </div>
      </KeyCreationStep>
      <KeyCreationStep
        mode={mode}
        setCurrentStep={setCurrentStep}
        stepName="Select address type"
        numSteps={5}
        title={
          <h2 className="font-medium text-gray-900 text-lg">
            <span className="capitalize">{addressType}</span> address:{` `}
            <span className="font-mono bg-violet-100 py-1 px-3 rounded-lg border-b-2 border-violet-200 text-base font-medium">
              {address || `______`}
            </span>
          </h2>
        }
        currentStep={currentStep}
        index={2}
      >
        <div className="flex justify-end mr-2 items-center">
          <label className="mr-2 text-gray-600">Advanced:</label>
          <Toggle
            enabled={advancedAddressOptions}
            small
            setEnabled={setAdvancedAddressOptions}
          />
        </div>
        <TextInput
          type={`text`}
          label={`Web address:`}
          value={address}
          setValue={setAddress}
          prefix={`https://`}
          className="mb-7"
        />
        <div className="bg-gray-50 px-2 py-4 rounded-lg">
          <div className="flex items-center justify-end">
            <label className="mr-2 text-gray-600 font-medium">Address type:</label>
            <SelectMenu
              options={
                [
                  `standard`,
                  `strict`,
                  advancedAddressOptions && `IP address`,
                  advancedAddressOptions && `regular expression`,
                  // don't love this
                ].filter((x) => typeof x === `string`) as string[]
              }
              selectedOption={capitalize(addressType)}
              setSelected={(option) => {
                setAddressType(
                  // or this
                  option as 'standard' | 'strict' | 'regular expression' | 'IP address',
                );
              }}
              deemphasized
            />
          </div>
          <div className="flex justify-end">
            {addressType === `standard` && (
              <p className="text-right max-w-lg text-sm text-gray-400 my-2">
                Allows any subdomain of{` `}
                <InlineURL domain={address || `____`} subdomains={[``]} />, for example
                {` `}
                <InlineURL
                  domain={address || `____`}
                  move
                  subdomains={[`images`, `cdn`, `static`, `api`, `docs`]}
                />
              </p>
            )}
            {addressType === `strict` && (
              <p className="text-right max-w-lg text-sm text-gray-400 my-2">
                Only allows access to{` `}
                <InlineURL domain={address || `____`} subdomains={[`www`]} />. Subdomains
                like{` `}
                <InlineURL
                  domain={address || `____`}
                  move
                  subdomains={[`images`, `cdn`, `static`, `api`, `docs`]}
                />
                {` `}
                are blocked
              </p>
            )}
          </div>
        </div>
      </KeyCreationStep>
      <KeyCreationStep
        mode={mode}
        setCurrentStep={setCurrentStep}
        stepName="Select scope"
        numSteps={5}
        title={
          <h2 className="font-medium text-gray-900 text-lg">Key effects {keyScope}</h2>
        }
        currentStep={currentStep}
        index={3}
      >
        <div>
          <h2 className="font-medium">Unlocked for:</h2>
          <div className="mt-3 space-y-0.5">
            <KeyScopeRadioOption
              title={`Web browsers`}
              description={`Applies to all browsers, like Chrome, Safari, Firefox, etc.`}
              selected={keyScope === `web browsers`}
              onClick={() => setKeyScope(`web browsers`)}
            />
            <KeyScopeRadioOption
              title={`All apps`}
              description={`Permits access for every app (including browsers). Use for sites you're sure you trust.`}
              selected={keyScope === `all apps`}
              onClick={() => setKeyScope(`all apps`)}
            />
            <KeyScopeRadioOption
              title={`Single app`}
              description={`Unlock this site for one specific app you choose.`}
              selected={keyScope === `single app`}
              onClick={() => setKeyScope(`single app`)}
            />
          </div>
          {keyScope === `single app` && (
            <div className="bg-gray-50 p-4 rounded-lg mt-4">
              <Combobox
                options={commonApplications}
                selectedOption={selectedApp}
                setSelectedOption={setSelectedApp}
              />
            </div>
          )}
        </div>
      </KeyCreationStep>
      <KeyCreationStep
        mode={mode}
        setCurrentStep={setCurrentStep}
        stepName="Miscellaneous"
        numSteps={5}
        title={<h1>Step 4</h1>}
        currentStep={currentStep}
        index={4}
      >
        <p>
          Lorem ipsum dolor sit amet consectetur adipisicing elit. Repudiandae quaerat
        </p>
      </KeyCreationStep>
      <KeyCreationStep
        mode={mode}
        setCurrentStep={setCurrentStep}
        stepName="Summary"
        numSteps={5}
        title={<h1>Step 5</h1>}
        currentStep={currentStep}
        index={5}
      >
        <p>
          Lorem ipsum dolor sit amet consectetur adipisicing elit. Repudiandae quaerat
        </p>
      </KeyCreationStep>
    </div>
  );
};

export default KeyCreator;

interface InlineURLProps {
  domain: string;
  move?: boolean;
  subdomains: string[];
}

const InlineURL: React.FC<InlineURLProps> = ({ domain, move = false, subdomains }) => {
  const [curIndex, setCurIndex] = useState(0);

  const shift = useCallback(() => {
    if (curIndex === subdomains.length - 1) {
      setCurIndex(0);
    } else {
      setCurIndex(curIndex + 1);
    }
  }, [curIndex, subdomains.length]);

  useEffect(() => {
    const id = setTimeout(shift, 3000);
    return () => {
      clearTimeout(id);
    };
  }, [curIndex, shift]);

  return (
    <span className="font-mono text-gray-500 px-1 rounded">
      <span
        className={cx(`relative [transition:200ms] overflow-hidden`, move && `ml-12`)}
      >
        {move
          ? subdomains.map((subd, index) => (
              <span
                className={cx(
                  `absolute right-0 [transition:200ms] opacity-0`,
                  index < curIndex && `-top-5`,
                  index === curIndex && `-top-0.5 opacity-100`,
                  index > curIndex && `top-5`,
                )}
              >
                {subd}
              </span>
            ))
          : subdomains[curIndex]}
      </span>
      {subdomains[curIndex] && `.`}
      {domain}
    </span>
  );
};
