import React from 'react';
import { Subcomponents, ConfirmableEntityAction } from '../../../types';
import Button from '../../../Button';
import KeychainCard from '../../Users/KeychainCard';
import PageHeading from '../../PageHeading';
import { ConfirmDeleteEntity } from '../../Modal';
import EmptyState from '../../EmptyState';

type Props = {
  keychains: Subcomponents<typeof KeychainCard>;
  remove: ConfirmableEntityAction;
  onCreateNew(): unknown;
};

const ListKeychains: React.FC<Props> = ({ keychains, remove, onCreateNew }) => (
  <div className="px-0 sm:px-4">
    <PageHeading icon="key">Keychains</PageHeading>
    <p className="mt-6 text-base antialiased text-gray-600">
      Keychains are clusters of related individual "keys" for selectively unlocking
      internet access. They can be organized however you like—per use, by application, for
      a specific school class, etc. Or, you can put all of your keys in one keychain if
      you prefer.
    </p>
    {keychains.length > 0 ? (
      <>
        <div className="grid grid-cols-1 xl:grid-cols-2 gap-10 lg+:gap-8 xl:gap-10 2xl:grid-cols-3 mt-10">
          {keychains.map(({ id, isPublic, name, description, numKeys }) => (
            <KeychainCard
              key={id}
              isPublic={isPublic}
              name={name}
              numKeys={numKeys}
              description={description}
              remove={{ text: `Delete`, handler: () => remove.start(id) }}
              editUrl={`/keychains/${id}`}
            />
          ))}
        </div>
        <div className="mt-10 flex justify-end border-t pt-8">
          <Button type="button" onClick={onCreateNew} color="primary-violet">
            <i className="fa fa-plus mr-2" /> Create keychain
          </Button>
        </div>
        <ConfirmDeleteEntity type="keychain" action={remove} />
      </>
    ) : (
      <EmptyState
        heading={'No keychains'}
        secondaryText={"Let's make one!"}
        icon={'key'}
        buttonText={'Create keychain'}
        onButtonClick={onCreateNew}
        className="mt-6"
      />
    )}
  </div>
);

export default ListKeychains;
