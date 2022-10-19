import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import cx from 'classnames';
import KeychainPicker from '../KeychainPicker';
import KeyCreator from '../Keychains/Keys/KeyCreator';
import { relativeTime } from '../lib/dates';
import { Step } from '../lib/keys/edit';
import Modal from '../Modal';
import { keychains } from '../story-helpers';
import Toggle from '../Toggle';
import UserInputText from '../Keychains/Keys/KeyCreator/UserInputText';

type Props = {
  step: 'preview request' | 'create key' | 'select keychain';
  userName: string;
  comment?: string;
  target: {
    url?: string;
    domain?: string;
    IPAddress?: string;
  };
  isOpen: boolean;
  dateRequested: Date;
  appName: string;
  appCategory: string;
  appBundleId: string;
  protocol: 'TCP' | 'UDP';
};

const UnlockRequestResponder: React.FC<Props> = ({
  step,
  userName,
  comment,
  target,
  isOpen,
  dateRequested,
  appName,
  appCategory,
  appBundleId,
  protocol,
}) => {
  const [appDetailsExpanded, setAppDetailsExpanded] = useState(false);
  if (step === `preview request`) {
    return (
      <Modal
        type={`container`}
        icon={`unlock`}
        title={`Unlock request`}
        isOpen={isOpen}
        primaryButtonText="Create key"
        secondaryButtonText="Deny"
        onPrimaryClick={() => {}}
        onDismiss={() => {}}
      >
        <div className="flex flex-col sm:flex-row justify-between items-center mb-4 px-3 pt-2">
          <div className="flex flex-col items-center sm:items-start mr-4">
            <h1 className="text-xl font-bold">{userName}</h1>
            <h3 className="text-gray-500">{relativeTime(dateRequested)}</h3>
          </div>
          <div className="mt-3 sm:mt-0">
            <UserInputText className="text-center sm:text-left">{comment}</UserInputText>
          </div>
        </div>
        <div className="bg-gray-50 p-3 rounded-xl overflow-scroll">
          <a
            className="text-blue-700 underline cursor-pointer whitespace-nowrap sm:whitespace-normal"
            href={
              target.url ||
              (target.domain && `https://${target.domain}`) ||
              target.IPAddress
            }
          >
            <i className="fa-solid fa-arrow-up-right-from-square mr-2" />
            {target.url || target.domain || target.IPAddress}
          </a>
        </div>
        <div className="bg-white border rounded-xl mb-1 flex flex-col mt-4 relative">
          <button
            className="hover:text-gray-600 text-gray-400 transition duration-100 absolute right-3 top-1 text-lg p-2 bg-transparent"
            onClick={() => {
              setAppDetailsExpanded(!appDetailsExpanded);
            }}
          >
            <i
              className={cx(
                `fa-solid fa-chevron-down`,
                appDetailsExpanded && '-rotate-180',
              )}
            />
          </button>
          <AppDetail label="App" data={appName} />
          {appDetailsExpanded && (
            <>
              <AppDetail label="App category" data={appCategory} />
              <AppDetail label="Bundle ID" data={appBundleId} />
              <AppDetail label="Protocol" data={protocol} />
              {target.url && <AppDetail label="URL" data={target.url} />}
              {target.domain && <AppDetail label="Domain" data={target.domain} />}
              {target.IPAddress && (
                <AppDetail label="IP Address" data={target.IPAddress} />
              )}
            </>
          )}
        </div>
      </Modal>
    );
  } else if (step === `create key`) {
    return (
      <Modal
        type={`container`}
        icon={`key`}
        title={`Create a key`}
        isOpen={isOpen}
        primaryButtonText="Select a keychain"
        secondaryButtonText="Back"
        onPrimaryClick={() => {}}
        onDismiss={() => {}}
      >
        <div className="px-2">
          <KeyCreator
            id={``}
            keychainId={``}
            isNew={false}
            address={``}
            addressType={`strict`}
            addressScope={`webBrowsers`}
            showAdvancedAddressOptions={false}
            showAdvancedAddressScopeOptions={false}
            appIdentificationType={`bundleId`}
            appScope={`address`}
            update={() => {}}
            apps={[]}
            activeStep={Step.None}
          />
        </div>
      </Modal>
    );
  }
  return (
    <Modal
      type={`container`}
      icon={`key`}
      title={`Select a keychain`}
      isOpen={isOpen}
      primaryButtonText="Save"
      secondaryButtonText="Back"
      onPrimaryClick={() => {}}
      onDismiss={() => {}}
    >
      <div>
        <KeychainPicker
          hasNoOwnKeychains={false}
          selectableOwnKeychains={keychains}
          selectablePublicKeychains={[]}
          onSelect={() => {}}
          includePublic={false}
        />
      </div>
    </Modal>
  );
};

export default UnlockRequestResponder;

interface AppDetailProps {
  label: string;
  data: string;
}

const AppDetail: React.FC<AppDetailProps> = ({ label, data }) => {
  return (
    <div className="flex items-center p-3 px-5 odd:bg-gray-50 last:rounded-b-xl overflow-scroll">
      <h3 className="text-gray-600 mr-3 font-medium whitespace-nowrap">{label}:</h3>
      <h2 className="text-gray-900 text-lg font-bold whitespace-nowrap">{data}</h2>
    </div>
  );
};
