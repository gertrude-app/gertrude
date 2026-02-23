import { Button } from '@shared/components';
import React from 'react';
import type { ConfirmableEntityAction } from '@dash/types';
import EmptyState from '../EmptyState';
import { ConfirmDeleteEntity } from '../Modal';
import PageHeading from '../PageHeading';
import KeychainCard from './KeychainCard';

type Props = {
  keychains: Array<{
    id: UUID;
    name: string;
    assignedChildren: UUID[];
    allChildren: Array<{
      name: string;
      id: UUID;
    }>;
    description?: string;
    numKeys: number;
    isPublic: boolean;
    toggleChild(childId: string): void;
  }>;
  remove: ConfirmableEntityAction;
  hasAnyMacComputers: boolean;
};

const ListKeychains: React.FC<Props> = ({ keychains, remove, hasAnyMacComputers }) => (
  <div>
    <PageHeading icon="key">Your Keychains</PageHeading>
    {keychains.length > 0 ? (
      <>
        <p className="mt-8 text-base font-medium antialiased text-slate-600">
          Keychains are clusters of related individual “keys” for selectively unlocking
          internet access. They can be organized however you like—per use, by application,
          for a specific school class, etc. Or, you can put all of your keys in one
          keychain if you prefer.
        </p>
        <div className="grid grid-cols-1 xl:grid-cols-2 gap-10 lg+:gap-8 2xl:grid-cols-3 mt-10 bg-slate-100/50 border border-slate-200 p-4 xs:p-8 rounded-3xl">
          {keychains.map(
            ({
              id,
              isPublic,
              name,
              description,
              numKeys,
              assignedChildren,
              allChildren,
              toggleChild,
            }) => (
              <KeychainCard
                mode="keychains_screen"
                key={id}
                id={id}
                assignedChildren={assignedChildren}
                allChildren={allChildren}
                isPublic={isPublic}
                name={name}
                numKeys={numKeys}
                description={description}
                onRemove={() => remove.start(id)}
                toggleChild={toggleChild}
              />
            ),
          )}
        </div>
        <div className="mt-10 flex justify-end">
          <Button size="large" type="link" to="/keychains/new" color="primary">
            <i className="fa fa-plus mr-2" /> Create keychain
          </Button>
        </div>
        <ConfirmDeleteEntity type="keychain" action={remove} />
      </>
    ) : hasAnyMacComputers ? (
      <EmptyState
        heading="No keychains"
        secondaryText="Let's make one!"
        icon="key"
        buttonText="Create keychain"
        action="/keychains/new"
        className="mt-8"
      />
    ) : (
      <div className="mt-8 flex flex-col items-center rounded-2xl bg-slate-100 shadow-inner p-8 sm:p-12">
        <div className="flex items-center gap-4">
          <div className="flex items-center justify-center w-12 h-12 rounded-full bg-slate-200/80">
            <i className="fa-solid fa-laptop text-lg text-slate-400" />
          </div>
          <h2 className="text-xl font-bold text-slate-700">
            Keychains are for the Gertrude Mac app
          </h2>
        </div>
        <p className="text-slate-500 text-center mt-4 max-w-lg leading-relaxed">
          Keychains let you selectively unlock specific websites and apps on a Mac{` `}
          <b>computer</b> protected by Gertrude. Since you don't have any Mac computers
          connected yet, there's nothing you need to do here.
        </p>
        <p className="text-slate-500 text-center mt-3 max-w-lg leading-relaxed">
          To try out the Mac app, download it from{` `}
          <span className="font-mono text-violet-600">gertrude.app/download</span> on the
          Mac your child uses, then launch it to get started.
        </p>
      </div>
    )}
  </div>
);

export default ListKeychains;
