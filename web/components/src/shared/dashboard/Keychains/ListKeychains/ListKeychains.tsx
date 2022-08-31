import React from 'react';
import Button from '../../../Button';
import KeychainCard from '../../Users/KeychainCard';
import PageHeading from '../../PageHeading';
import { Subcomponents } from '../../../types';

type Props = {
  keychains: Subcomponents<typeof KeychainCard>;
  removeKeychain(id: UUID): unknown;
};

const Keychains: React.FC<Props> = ({ keychains, removeKeychain }) => (
  <div className="px-0 sm:px-4">
    <PageHeading icon="key">Keychains</PageHeading>
    <p className="mt-4 text-sm text-gray-500">
      Keychains are clusters of related individual "keys" for selectively unlocking
      internet access. They can be organized however you like—per use, by application, for
      a specific school class, etc. Or, you can put all of your keys in one keychain if
      you prefer.
    </p>
    <div className="grid grid-cols-1 lg+:grid-cols-2 gap-10 lg+:gap-8 xl:gap-10 2xl:grid-cols-3 mt-10">
      {keychains.map(({ id, isPublic, name, description, keys }) => (
        <KeychainCard
          key={id}
          isPublic={isPublic}
          name={name}
          keys={keys}
          description={description}
          onRemove={() => removeKeychain(id)}
          editable
        />
      ))}
    </div>
    <div className="mt-8 flex justify-end border-t pt-6">
      <Button type="button" onClick={() => {}} color="primary-violet">
        <i className="fa fa-plus mr-2" /> Create keychain
      </Button>
    </div>
  </div>
);

export default Keychains;
