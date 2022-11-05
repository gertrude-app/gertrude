import React from 'react';
import { v4 as uuid } from 'uuid';
import cx from 'classnames';
import { relativeTime } from '@dash/datetime';
import { EditKey, Keychain, newKeyState } from '@dash/keys';
import { UnlockRequest } from '@dash/types';
import KeychainPicker from '../Keychains/KeychainPicker';
import KeyCreator from '../KeyCreator/KeyCreator';
import UserInputText from '../UserInputText';

type Props = {
  step: 'reviewing' | 'editingKey' | 'selectingKeychain';
  detailsExpanded: boolean;
  setDetailsExpanded(expanded: boolean): unknown;
  editingKey?: EditKey.State;
  updateKey(update: EditKey.Event): unknown;
  apps: React.ComponentProps<typeof KeyCreator>['apps'];
  selectableKeychains: Keychain[];
} & UnlockRequest;

const UnlockRequestResponder: React.FC<Props> = ({
  step,
  userName,
  requestComment,
  editingKey,
  updateKey,
  url,
  domain,
  ipAddress,
  createdAt,
  appName,
  appCategories,
  appBundleId,
  requestProtocol,
  detailsExpanded,
  setDetailsExpanded,
  selectableKeychains,
  apps,
}) => {
  if (step === `reviewing`) {
    return (
      <>
        <div className="flex flex-col sm:flex-row justify-between items-center sm:items-start mb-4 px-3 sm:pt-2">
          <div className="flex flex-col items-center sm:items-start sm:min-w-[105px] mr-4">
            <h1 className="text-xl font-bold whitespace-nowrap pr-3">{userName}</h1>
            <h3 className="text-gray-500">{relativeTime(createdAt)}</h3>
          </div>
          {requestComment && (
            <div className="mt-3 sm:mt-0">
              <UserInputText className="text-center sm:text-left">
                &ldquo;{requestComment}&rdquo;
              </UserInputText>
            </div>
          )}
        </div>
        <div className="bg-gray-50 p-3 rounded-xl *overflow-scroll">
          <a
            className="text-blue-700 hover:underline focus:outline-none cursor-pointer break-all"
            href={url || (domain && `https://${domain}`) || ipAddress}
            target="_blank"
            rel="noopener noreferrer"
          >
            <i className="fa-solid fa-arrow-up-right-from-square mr-2" />
            {url || domain || ipAddress}
          </a>
        </div>
        <div className="bg-white border rounded-xl mb-1 flex flex-col mt-4 relative">
          <button
            className="hover:text-gray-600 text-gray-400 transition duration-100 absolute right-2.5 top-0 text-lg p-2 bg-transparent"
            onClick={() => setDetailsExpanded(!detailsExpanded)}
          >
            <i
              className={cx(`fa-solid fa-chevron-down`, detailsExpanded && `-rotate-180`)}
            />
          </button>
          {appName ? (
            <AppDetail expanded={detailsExpanded} label="App" data={appName} />
          ) : (
            <AppDetail
              expanded={detailsExpanded}
              label="App Bundle ID"
              data={appBundleId}
            />
          )}
          {detailsExpanded && (
            <>
              <AppDetail
                expanded={detailsExpanded}
                label="App category"
                data={appCategories.join(`, `)}
              />
              {appName && (
                <AppDetail
                  expanded={detailsExpanded}
                  label="Bundle ID"
                  data={appBundleId}
                />
              )}
              <AppDetail
                expanded={detailsExpanded}
                label="Protocol"
                data={requestProtocol}
              />
              <AppDetail expanded={detailsExpanded} label="URL" data={url} />
              <AppDetail expanded={detailsExpanded} label="Domain" data={domain} />
              <AppDetail expanded={detailsExpanded} label="IP Address" data={ipAddress} />
            </>
          )}
        </div>
      </>
    );
  } else if (step === `editingKey`) {
    return (
      <div className="px-2">
        <KeyCreator
          {...(editingKey ?? newKeyState(uuid(), uuid()))}
          update={updateKey}
          apps={apps}
        />
      </div>
    );
  }
  return (
    <KeychainPicker
      hasNoOwnKeychains={selectableKeychains.length === 0}
      includePublic={false}
      selectableOwnKeychains={selectableKeychains}
      selectablePublicKeychains={[]}
      onSelect={(keychain) => updateKey({ type: `setKeychainId`, to: keychain.id })}
      selected={
        selectableKeychains.find((keychain) => keychain.id === editingKey?.keychainId) ??
        null
      }
    />
  );
};

export default UnlockRequestResponder;

interface AppDetailProps {
  expanded: boolean;
  label: string;
  data?: string;
}

const AppDetail: React.FC<AppDetailProps> = ({ label, data, expanded }) => {
  if (!data) {
    return null;
  }
  return (
    <div className="flex items-start p-3 px-5 text-sm sm:text-md odd:bg-gray-50 last:rounded-b-xl">
      <h3
        className={cx(
          `text-gray-600 antialiased pr-3 font-medium`,
          expanded && `min-w-[108px]`,
        )}
      >
        {label}:
      </h3>
      <h2 className="text-gray-900 *font-mono font-bold break-all">{data}</h2>
    </div>
  );
};
