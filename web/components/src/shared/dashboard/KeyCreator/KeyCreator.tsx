import React, { useCallback, useEffect, useState } from 'react';
import KeyCreationStep from '../KeyCreationStep';
import cx from 'classnames';
import KeyTypeOption from '../KeyTypeOption';
import TextInput from '../TextInput';
import Toggle from '../Toggle';
import SelectMenu from '../SelectMenu';
import KeyScopeRadioOption from '../SelectableListItem';
import Combobox, { ComboboxOption } from '../Combobox/Combobox';
import RadioGroup from '../RadioGroup';
import TextArea from '../TextArea';
import { formatDateAndTimeFromInputElements } from '../../lib/dates';
import SummaryLi from '../SummaryLi';
import Label from '../TextInput/Label';
import SelectableListItem from '../SelectableListItem';

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
  const [advancedKeyScope, setAdvancedKeyScope] = useState(false);
  const [keyScope, setKeyScope] = useState<'web browsers' | 'all apps' | 'single app'>(
    `web browsers`,
  );
  const [selectedApp, setSelectedApp] = useState<ComboboxOption>({ name: ``, id: `` });
  const [appSelectionMethod, setAppSelectionMethod] = useState<
    'choose from common apps' | 'by bundle id'
  >(`choose from common apps`);
  const [appBundleId, setAppBundleId] = useState(``);
  const [expires, setExpires] = useState(false);
  const [expiryDate, setExpiryDate] = useState(``);
  const [expiryTime, setExpiryTime] = useState(``);
  const [comment, setComment] = useState(``);
  const [keyPower, setKeyPower] = useState<'all' | 'one'>(`all`);

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
      {/* key type */}
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

      {/* address type */}
      {keyType === `website` && (
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
          <TextInput
            type={`text`}
            label={`Web address:`}
            value={address}
            setValue={setAddress}
            prefix={`https://`}
            className="mb-7"
          />
          <div className="bg-gray-50 px-2 py-4 rounded-lg">
            <div className="flex justify-start mr-2 items-center ml-2 mb-2">
              <label className="mr-2 text-gray-600">Advanced:</label>
              <Toggle
                enabled={advancedAddressOptions}
                small
                setEnabled={setAdvancedAddressOptions}
              />
            </div>
            <div className="flex items-center justify-end">
              <label className="mr-2 text-gray-600 font-medium">Address type:</label>
              <SelectMenu
                options={
                  [
                    { value: `standard`, display: `Standard` },
                    { value: `strict`, display: `Strict` },
                    {
                      value: advancedAddressOptions && `IP address`,
                      display: `IP address`,
                    },
                    {
                      value: advancedAddressOptions && `regular expression`,
                      display: `Regular expression`,
                    },
                  ].filter((x) => typeof x.value === `string`) as {
                    value: string;
                    display: string;
                  }[]
                }
                selectedOption={addressType}
                setSelected={(option) => {
                  setAddressType(
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
                  <InlineURL domain={address || `____`} subdomains={[`www`]} />.
                  Subdomains like{` `}
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
      )}
      {/* key scope */}
      {keyType === `website` && (
        <KeyCreationStep
          mode={mode}
          setCurrentStep={setCurrentStep}
          stepName="Select scope"
          numSteps={5}
          title={
            <h2 className="font-medium text-gray-900 text-lg">
              Key effects {keyScope}
              {keyScope === `single app` &&
                appSelectionMethod === `choose from common apps` && (
                  <span>
                    : <span className="font-bold">{selectedApp.name}</span>
                  </span>
                )}
            </h2>
          }
          currentStep={currentStep}
          index={3}
        >
          <div>
            <h2 className="font-medium">Unlocked for:</h2>
            <div className="flex justify-end mr-2 items-center">
              <label className="mr-2 text-gray-600">Advanced:</label>
              <Toggle
                enabled={advancedKeyScope}
                small
                setEnabled={(b) => {
                  if (!b && keyScope === `single app`) setKeyScope(`web browsers`);
                  setAppBundleId(``);
                  setSelectedApp({ name: ``, id: `` });
                  setAdvancedKeyScope(b);
                }}
              />
            </div>
            <div className="mt-3 space-y-0.5">
              <KeyScopeRadioOption
                title={`Web browsers`}
                description={`Applies to all browsers, like Chrome, Safari, Firefox, etc.`}
                selected={keyScope === `web browsers`}
                onClick={() => setKeyScope(`web browsers`)}
                badges={[{ text: `Most common`, color: `green` }]}
              />
              <KeyScopeRadioOption
                title={`All apps`}
                description={`Permits access for every app (including browsers). Use for sites you're sure you trust.`}
                selected={keyScope === `all apps`}
                onClick={() => setKeyScope(`all apps`)}
              />
              {advancedKeyScope && (
                <KeyScopeRadioOption
                  title={`Single app`}
                  description={`Unlock this site for one specific app you choose.`}
                  selected={keyScope === `single app`}
                  onClick={() => setKeyScope(`single app`)}
                />
              )}
            </div>
            {keyScope === `single app` && (
              <div className="bg-gray-50 p-4 rounded-lg mt-4">
                <RadioGroup
                  options={[`choose from common apps`, `by bundle id`]}
                  selectedOption={appSelectionMethod}
                  setSelectedOption={setAppSelectionMethod as (s: string) => void}
                  className="mb-4"
                />
                {appSelectionMethod === `choose from common apps` ? (
                  <div>
                    <label className="text-gray-600 font-bold">Choose application:</label>
                    <Combobox
                      options={commonApplications}
                      selectedOption={selectedApp}
                      setSelectedOption={setSelectedApp}
                    />
                  </div>
                ) : (
                  <TextInput
                    type={`text`}
                    label={`App bundle ID:`}
                    value={appBundleId}
                    setValue={setAppBundleId}
                  />
                )}
              </div>
            )}
          </div>
        </KeyCreationStep>
      )}

      {/* app picker */}
      {keyType === `app` && (
        <KeyCreationStep
          mode={mode}
          setCurrentStep={setCurrentStep}
          stepName="Choose application"
          numSteps={5}
          title={
            <h2 className="font-medium text-gray-900 text-lg">
              Key for {appSelectionMethod === `by bundle id` && `app with bundle id `}
              <span className="font-bold">
                {appSelectionMethod === `choose from common apps`
                  ? selectedApp.name
                  : appBundleId
                  ? appBundleId
                  : `________`}
              </span>
            </h2>
          }
          currentStep={currentStep}
          index={2}
        >
          <div>
            <RadioGroup
              options={[`choose from common apps`, `by bundle id`]}
              selectedOption={appSelectionMethod}
              setSelectedOption={setAppSelectionMethod as (s: string) => void}
              className="mb-4"
            />
            {appSelectionMethod === `choose from common apps` ? (
              <div>
                <label className="text-gray-600 font-bold">Choose application:</label>
                <Combobox
                  options={commonApplications}
                  selectedOption={selectedApp}
                  setSelectedOption={setSelectedApp}
                />
              </div>
            ) : (
              <TextInput
                type={`text`}
                label={`App bundle ID:`}
                value={appBundleId}
                setValue={setAppBundleId}
              />
            )}
          </div>
        </KeyCreationStep>
      )}

      {/* key power */}
      {keyType === `app` && (
        <KeyCreationStep
          mode={mode}
          setCurrentStep={setCurrentStep}
          stepName="Choose key power" // I don't know what to call this
          numSteps={5}
          title={
            <h2 className="font-medium text-gray-900 text-lg">
              {keyPower === `all` ? (
                `App gets unrestricted network requests`
              ) : (
                <span>
                  App can access{` `}
                  <span className="font-mono bg-violet-100 py-1 px-3 rounded-lg border-b-2 border-violet-200 text-base font-medium">
                    {address}
                  </span>
                </span>
              )}
            </h2>
          }
          currentStep={currentStep}
          index={3}
        >
          <Label>Key grants application:</Label>
          <div className="space-y-0.5 mt-3">
            <SelectableListItem
              title={`Unrestricted internet access`}
              description={`Allows this app unrestricted network requests. Only for narrowly-focused apps that you trust.`}
              selected={keyPower === `all`}
              onClick={() => setKeyPower(`all`)}
              badges={[{ text: `Most common`, color: `green` }]}
            />
            <SelectableListItem
              title={`Access to a specific address`}
              description={`Allow this application to access a specific address.`}
              selected={keyPower === `one`}
              onClick={() => setKeyPower(`one`)}
              badges={[
                { text: `Most safe`, color: `green` },
                { text: `Advanced`, color: `yellow` },
              ]}
            />
          </div>
          {keyPower === `one` && (
            <div className="mt-4">
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
                        { value: `standard`, display: `Standard` },
                        { value: `strict`, display: `Strict` },
                        {
                          value: advancedAddressOptions && `IP address`,
                          display: `IP address`,
                        },
                        {
                          value: advancedAddressOptions && `regular expression`,
                          display: `Regular expression`,
                        },
                      ].filter((x) => typeof x.value === `string`) as {
                        value: string;
                        display: string;
                      }[]
                    }
                    selectedOption={addressType}
                    setSelected={(option) => {
                      setAddressType(
                        // or this
                        option as
                          | 'standard'
                          | 'strict'
                          | 'regular expression'
                          | 'IP address',
                      );
                    }}
                    deemphasized
                  />
                </div>
                <div className="flex justify-end">
                  {addressType === `standard` && (
                    <p className="text-right max-w-lg text-sm text-gray-400 my-2">
                      Allows any subdomain of{` `}
                      <InlineURL domain={address || `____`} subdomains={[``]} />, for
                      example
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
                      <InlineURL domain={address || `____`} subdomains={[`www`]} />.
                      Subdomains like{` `}
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
            </div>
          )}
        </KeyCreationStep>
      )}

      {/* miscellaneous */}
      <KeyCreationStep
        mode={mode}
        setCurrentStep={setCurrentStep}
        stepName="Miscellaneous"
        numSteps={5}
        title={
          <h2 className="font-medium text-gray-900 text-lg">
            {expires
              ? expiryDate && expiryTime
                ? `Key expires ${formatDateAndTimeFromInputElements(
                    expiryDate,
                    expiryTime,
                  )}`
                : `Key expires`
              : `Key never expires`}
          </h2>
        }
        currentStep={currentStep}
        index={4}
      >
        <div className="flex justify-end mr-2 items-center">
          <label className="mr-2 text-gray-600">Expires:</label>
          <Toggle enabled={expires} small setEnabled={setExpires} />
        </div>
        {expires && (
          <div className="flex flex-col sm:flex-row mt-4">
            <TextInput
              type={`date`}
              value={expiryDate}
              setValue={setExpiryDate}
              label="Expiration date:"
              className="sm:mr-2 mb-4 sm:mb-0"
            />
            <TextInput
              type={`time`}
              value={expiryTime}
              setValue={setExpiryTime}
              label="Expiration time:"
              className="sm:ml-2"
            />
          </div>
        )}
        <TextArea
          value={comment}
          setValue={setComment}
          label="Comment:"
          placeholder="Optional note to yourself about this key"
          className="mt-6"
        />
      </KeyCreationStep>

      {/* summary */}
      <KeyCreationStep
        mode={mode}
        setCurrentStep={setCurrentStep}
        stepName="Summary"
        numSteps={5}
        title={<h2 className="font-medium text-gray-900 text-lg">Summary:</h2>}
        currentStep={currentStep}
        index={5}
      >
        <ul className="">
          <SummaryLi prefix={`Key type`} data={keyType} />
          <SummaryLi
            prefix={`Key grants`}
            data={
              keyPower === `all`
                ? `unrestricted network requests`
                : `access to one domain`
            }
          />
          {(keyType === `website` || keyPower === `one`) && (
            <SummaryLi
              prefix={`Address`}
              data={address || `_______`}
              dataFormat="font-mono font-medium bg-gray-50 px-2 rounded shadow"
            />
          )}
          {(keyType === `website` || keyPower === `one`) && (
            <SummaryLi prefix={`Address type`} data={addressType} />
          )}
          {keyType === `website` && <SummaryLi prefix={`Key scope`} data={keyScope} />}
          {(keyScope === `single app` || keyType === `app`) && (
            <SummaryLi
              prefix={`App`}
              data={
                appSelectionMethod === `by bundle id` ? appBundleId : selectedApp.name
              }
            />
          )}
          <SummaryLi
            prefix={`Expiration`}
            data={
              expires
                ? formatDateAndTimeFromInputElements(expiryDate, expiryTime)
                : `none`
            }
          />
          <SummaryLi
            prefix={`Comment`}
            data={comment || `none`}
            dataFormat="font-normal text-gray-500 italic"
          />
        </ul>
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
