import React from 'react';
import { Button } from '@shared/components';
import type { Subcomponents, ConfirmableEntityAction } from '@dash/types';
import EmptyState from '../EmptyState';
import { ConfirmDeleteEntity } from '../Modal';
import PageHeading from '../PageHeading';
import KeychainCard from './KeychainCard';

type Props = {
  keychains: Subcomponents<typeof KeychainCard>;
  remove: ConfirmableEntityAction;
  onCreateNew(): unknown;
};

const ListKeychains: React.FC<Props> = ({ keychains, remove, onCreateNew }) => (
  <div>
    <PageHeading icon="key">Keychains</PageHeading>
    <p className="mt-8 text-base font-medium antialiased text-slate-600">
      Keychains are clusters of related individual "keys" for selectively unlocking
      internet access. They can be organized however you like—per use, by application, for
      a specific school class, etc. Or, you can put all of your keys in one keychain if
      you prefer.
    </p>
    {keychains.length > 0 ? (
      <>
        <div className="grid grid-cols-1 xl:grid-cols-2 gap-10 lg+:gap-8 2xl:grid-cols-3 mt-10 bg-slate-100 border p-8 rounded-3xl">
          {keychains.map(({ id, isPublic, name, description, numKeys }) => (
            <KeychainCard
              mode="list"
              key={id}
              isPublic={isPublic}
              name={name}
              numKeys={numKeys}
              description={description}
              onRemove={() => remove.start(id)}
              removeText="Delete"
              editUrl={`/keychains/${id}`}
            />
          ))}
        </div>
        <div className="mt-10 flex justify-end">
          <Button size="large" type="button" onClick={onCreateNew} color="primary">
            <i className="fa fa-plus mr-2" /> Create keychain
          </Button>
        </div>
        <ConfirmDeleteEntity type="keychain" action={remove} />
      </>
    ) : (
      <EmptyState
        heading={`No keychains`}
        secondaryText={`Let's make one!`}
        icon={`key`}
        buttonText={`Create keychain`}
        action={onCreateNew}
        className="mt-8"
      />
    )}
  </div>
);

export default ListKeychains;
