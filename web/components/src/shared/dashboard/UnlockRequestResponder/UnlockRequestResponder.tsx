import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import KeychainPicker from '../KeychainPicker';
import KeyCreator from '../Keychains/Keys/KeyCreator';
import { relativeTime } from '../lib/dates';
import { Step } from '../lib/keys/edit';
import Modal from '../Modal';
import { keychains } from '../story-helpers';
import Toggle from '../Toggle';

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
  const [advanced, setAdvanced] = useState(false);
  const [appDetailsExpanded, setAppDetailsExpanded] = useState(false);
  if (step === `preview request`) {
    return (
      <Modal
        type={`container`}
        icon={`unlock`}
        title={`Unlock request from ${userName}`}
        isOpen={isOpen}
        primaryButtonText="Create key"
        secondaryButtonText="Deny"
        onPrimaryClick={() => {}}
        onDismiss={() => {}}
      >
        <h3 className="absolute right-5 top-7 text-lg font-medium text-gray-500">
          {relativeTime(dateRequested)}
        </h3>
        <div className="flex flex-col">
          <div className="flex justify-center items-center p-4 relative">
            <i className="fa-solid fa-quote-left absolute left-5 text-5xl text-gray-200 opacity-70 z-0" />
            <i className="fa-solid fa-quote-right absolute right-5 text-5xl text-gray-200 opacity-70 z-0" />
            <p className="text-center text-lg text-gray-500 font-medium relative z-10">
              {comment || `No comment`}
            </p>
          </div>
          <div className="flex flex-col bg-gray-50 p-4 mt-3 rounded-xl">
            <div className="flex items-center justify-between mb-3">
              <h2 className="font-bold text-lg text-gray-800">
                {userName} wants access to:
              </h2>
              <div className="flex items-center">
                <label className="mr-2 text-gray-600">Advanced:</label>
                <Toggle enabled={advanced} small setEnabled={setAdvanced} />
              </div>
            </div>
            <div className="flex-grow">
              {advanced ? (
                <div>
                  {target.url && <TargetCard target={target.url} type={`URL`} />}
                  {target.domain && <TargetCard target={target.domain} type={`Domain`} />}
                  {target.IPAddress && (
                    <TargetCard target={target.IPAddress} type={`IP address`} />
                  )}
                </div>
              ) : (
                <div className="border bg-white p-3 rounded-xl shadow overflow-hidden">
                  <Link
                    className="text-indigo-600 hover:text-indigo-700 transition duration-75 text-lg underline whitespace-nowrap"
                    to={target.url || (target.domain && `https://${target.domain}`)!} // not sure how hrefs with ip addresses work
                  >
                    <i className="fa-solid fa-arrow-up-right-from-square mr-2" />
                    {target.url || target.domain || target.IPAddress}
                  </Link>
                </div>
              )}
            </div>
          </div>
          <div className="bg-white border rounded-xl mb-3 flex flex-col mt-4">
            <AppDetail label="App" data={appName} />
            {appDetailsExpanded && (
              <>
                <AppDetail label="App category" data={appCategory} />
                <AppDetail label="App Bundle ID" data={appBundleId} />
                <AppDetail label="Protocol" data={protocol} />
              </>
            )}
            <div className="flex justify-center items-center py-1">
              <button
                className="p-2 px-4 hover:bg-violet-50 rounded-lg hover:text-violet-500 text-gray-500 transition duration-100"
                onClick={() => {
                  setAppDetailsExpanded(!appDetailsExpanded);
                }}
              >
                {appDetailsExpanded ? `See less` : `See more`}
              </button>
            </div>
          </div>
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
          noPublic
        />
      </div>
    </Modal>
  );
};

export default UnlockRequestResponder;

interface TargetCardProps {
  target: string;
  type: 'IP address' | 'Domain' | 'URL';
}

const TargetCard: React.FC<TargetCardProps> = ({ target, type }) => {
  return (
    <div className="bg-white border shadow rounded-xl mb-3 p-3 flex flex-col items-start">
      <h4 className="text-xs text-gray-500 font-medium uppercase">{type}</h4>
      <Link
        className="text-indigo-600 hover:text-indigo-700 transition duration-75 text-lg underline mt-1 cursor-pointer"
        to={type === `URL` ? target : `https://${target}`}
      >
        <i className="fa-solid fa-arrow-up-right-from-square mr-2" />
        {target}
      </Link>
    </div>
  );
};

interface AppDetailProps {
  label: string;
  data: string;
}

const AppDetail: React.FC<AppDetailProps> = ({ label, data }) => {
  return (
    <div className="flex items-center p-3 px-5 even:bg-gray-50">
      <h3 className="text-gray-600 mr-3 font-medium">{label}:</h3>
      <h2 className="text-gray-900 text-lg font-bold">{data}</h2>
    </div>
  );
};
