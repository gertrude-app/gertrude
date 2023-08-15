import React from 'react';
import cx from 'classnames';
import type { KeychainSummary as Keychain } from '@dash/types';
import EmptyState from '../EmptyState';
import KeychainCard from './KeychainCard';

type Props = {
  mode: 'addToUser' | 'forUnlockRequestKey';
  hasNoOwnKeychains: boolean;
  selectableOwnKeychains: Keychain[];
  selectablePublicKeychains: Keychain[];
  onSelect(keychain: Keychain): unknown;
  selectedId?: UUID;
  userName: string;
  userId: string;
};

const KeychainPicker: React.FC<Props> = ({
  mode,
  hasNoOwnKeychains,
  selectableOwnKeychains,
  selectedId,
  selectablePublicKeychains,
  onSelect,
  userId,
  userName,
}) => (
  <div
    className={cx(
      `flex flex-col gap-6 *sm:bg-slate-50 xs:min-w-[450px] rounded-xl *sm:p-4`,
      (selectableOwnKeychains.length > 0 || mode === `addToUser`) &&
        `sm:bg-slate-50 sm:p-4`,
    )}
  >
    {selectableOwnKeychains.length !== 0 && (
      <div>
        {mode === `addToUser` && (
          <h2 className="text-lg font-bold text-slate-600 mb-3">Your keychains:</h2>
        )}
        <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
          {selectableOwnKeychains.map((keychain) => (
            <KeychainCard
              mode="select"
              key={keychain.id}
              name={keychain.name}
              numKeys={keychain.numKeys}
              isPublic={keychain.isPublic}
              onSelect={() => onSelect(keychain)}
              selected={selectedId === keychain.id}
            />
          ))}
        </div>
      </div>
    )}
    {hasNoOwnKeychains && (
      <EmptyState
        icon="key"
        heading={mode === `addToUser` ? `No personal keychains` : `No keychains`}
        secondaryText={
          mode === `addToUser`
            ? `Select a public keychain below, or create a keychain of your own.`
            : `Before you can accept this unlock request, ${userName} needs to have at least one keychain created by you.`
        }
        buttonText="Create a keychain"
        action="/keychains"
      />
    )}
    {!hasNoOwnKeychains && selectableOwnKeychains.length === 0 && (
      <EmptyState
        icon="key"
        heading={
          mode === `forUnlockRequestKey` ? `No keychains` : `No selectable keychains`
        }
        secondaryText={
          mode === `forUnlockRequestKey`
            ? `Before you can accept this unlock request, ${userName} needs to have at least one keychain created by you.`
            : `${userName} already has all of your keychains. You can create a new one, or choose a public keychain below.`
        }
        buttonText="Create a keychain"
        action="/keychains"
        secondaryButton={
          mode === `forUnlockRequestKey`
            ? {
                text: `Assign a keychain`,
                action: `/children/${userId}`,
                icon: `user`,
              }
            : undefined
        }
      />
    )}

    {mode === `addToUser` && selectablePublicKeychains.length > 0 && (
      <div>
        <h2 className={cx(`text-lg font-bold text-slate-600 mb-3`)}>Public keychains:</h2>
        <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
          {selectablePublicKeychains.map((keychain) => (
            <KeychainCard
              mode="select"
              key={keychain.id}
              name={keychain.name}
              numKeys={keychain.numKeys}
              isPublic={keychain.isPublic}
              onSelect={() => onSelect(keychain)}
              selected={selectedId === keychain.id}
            />
          ))}
        </div>
      </div>
    )}
  </div>
);

export default KeychainPicker;
