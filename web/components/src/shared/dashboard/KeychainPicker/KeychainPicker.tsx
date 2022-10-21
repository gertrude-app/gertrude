import React from 'react';
import cx from 'classnames';
import KeychainCard from '../Users/KeychainCard';
import Button from '../../Button';

type Props = {
  hasNoOwnKeychains: boolean;
  selectableOwnKeychains: Keychain[];
  selectablePublicKeychains: Keychain[];
  onSelect(keychain: Keychain): unknown;
  selected?: Keychain | null;
  includePublic?: boolean;
};

const KeychainPicker: React.FC<Props> = ({
  hasNoOwnKeychains,
  selectableOwnKeychains,
  selected,
  selectablePublicKeychains,
  onSelect,
  includePublic = true,
}) => (
  <div className="sm:bg-gray-50 xs:min-w-[450px] rounded-xl sm:p-4">
    {selectableOwnKeychains.length !== 0 && (
      <>
        <h2 className="text-lg font-bold text-gray-600 mb-3">Your keychains:</h2>
        <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
          {selectableOwnKeychains.map((keychain) => (
            <KeychainCard
              key={keychain.id}
              name={keychain.name}
              numKeys={keychain.numKeys}
              isPublic={keychain.isPublic}
              onSelect={() => onSelect(keychain)}
              selected={selected?.id === keychain.id}
              selectable
              small
            />
          ))}
        </div>
      </>
    )}
    {hasNoOwnKeychains && (
      <div className="flex flex-col justify-center items-center p-10 bg-gray-100 rounded-2xl shadow-inner">
        <i className="fa fa-key text-6xl text-gray-300" />
        <h2 className="text-xl font-bold mt-3 mb-2 text-center">No personal keychains</h2>
        <p className="text-gray-500 text-center">
          Select a public keychain or create your own.
        </p>
        <Button
          color="primary-violet"
          type="button"
          onClick={() => {}}
          className="mt-6"
          small
        >
          <i className="fa fa-plus mr-4" />
          Create keychain
        </Button>
      </div>
    )}
    {includePublic && (
      <>
        <h2
          className={cx(
            `text-lg font-bold text-gray-600 mb-3`,
            selectableOwnKeychains.length > 0 && `mt-8`,
          )}
        >
          Public keychains:
        </h2>
        <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
          {selectablePublicKeychains.map((keychain) => (
            <KeychainCard
              key={keychain.id}
              name={keychain.name}
              numKeys={keychain.numKeys}
              isPublic={keychain.isPublic}
              selectable
              onSelect={() => onSelect(keychain)}
              selected={selected?.id === keychain.id}
              small
            />
          ))}
        </div>
      </>
    )}
  </div>
);

export default KeychainPicker;
