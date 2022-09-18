import React from 'react';
import KeychainCard from '../Users/KeychainCard';
import { SubcomponentsOmit } from '../../types';
import Button from '../../Button';

type Props = {
  keychains: SubcomponentsOmit<typeof KeychainCard, 'onRemove'>;
  publicKeychains: SubcomponentsOmit<typeof KeychainCard, 'onRemove'>;
};

const KeychainPicker: React.FC<Props> = ({ keychains, publicKeychains }) => (
  <div className="bg-gray-50 rounded-xl p-4">
    {keychains.length !== 0 ? (
      <>
        <h2 className="text-lg font-bold text-gray-600 mb-3">Your keychains</h2>
        <div className="space-y-3">
          {keychains.map((keychain) => (
            <KeychainCard
              name={keychain.name}
              keys={keychain.keys}
              isPublic={keychain.isPublic}
              onRemove={() => {}}
              selectable
              small
            />
          ))}
        </div>
      </>
    ) : (
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
    <h2 className="text-lg font-bold text-gray-600 mb-3 mt-6">Public keychains</h2>
    <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
      {publicKeychains
        .filter((k) => k.isPublic)
        .map((keychain) => (
          <KeychainCard
            name={keychain.name}
            keys={keychain.keys}
            isPublic={keychain.isPublic}
            onRemove={() => {}}
            selectable
            small
          />
        ))}
    </div>
  </div>
);

export default KeychainPicker;
