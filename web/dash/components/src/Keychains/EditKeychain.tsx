import React, { useState } from 'react';
import { Button, TextInput, Toggle } from '@shared/components';
import { inflect } from '@shared/string';
import type { ConfirmableEntityAction, Key } from '@dash/types';
import type { EditKey } from '@dash/keys';
import Modal, { ConfirmDeleteEntity } from '../Modal';
import PageHeading from '../PageHeading';
import KeyCreator from '../KeyCreator/KeyCreator';
import KeyList from '../Keychains/KeyList';
import EmptyState from '../EmptyState';

type Props = {
  isNew: boolean;
  name: string;
  description: string;
  setName(name: string): unknown;
  setDescription(description: string): unknown;
  deleteKeychain: ConfirmableEntityAction<void>;
  deleteKey: ConfirmableEntityAction;
  keys: Key[];
  saveButtonDisabled: boolean;
  onSave(): unknown;
  editingKey?: EditKey.State;
  beginEditKey(id: UUID): unknown;
  updateEditingKey(event: EditKey.Event): unknown;
  dismissEditKeyModal(): unknown;
  onKeySave(): unknown;
  onCreateNewKey(): unknown;
  keyModalSaveButtonDisabled: boolean;
  apps: React.ComponentProps<typeof KeyCreator>['apps'];
};

const EditKeychain: React.FC<Props> = ({
  isNew,
  name,
  description,
  setName,
  setDescription,
  keys,
  deleteKeychain,
  deleteKey,
  saveButtonDisabled,
  onSave,
  editingKey,
  updateEditingKey,
  dismissEditKeyModal,
  onKeySave,
  beginEditKey,
  onCreateNewKey,
  keyModalSaveButtonDisabled,
  apps,
}) => {
  const [viewMode, setViewMode] = useState<'list' | 'table'>('list');
  return (
    <div className="relative max-w-6xl">
      <Modal
        icon="key"
        type="container"
        maximizeWidthForSmallScreens
        title={editingKey?.isNew ? `Create a new key` : `Edit key`}
        isOpen={!!editingKey}
        primaryButton={{
          label: (
            <>
              {editingKey?.isNew ? `Create` : `Save`} key
              <i className="fa-solid fa-key ml-2" />
            </>
          ),
          action: onKeySave,
          disabled: keyModalSaveButtonDisabled,
        }}
        secondaryButton={{ action: dismissEditKeyModal }}
      >
        {editingKey && (
          <KeyCreator update={updateEditingKey} {...editingKey} apps={apps} />
        )}
      </Modal>
      <ConfirmDeleteEntity type="keychain" action={deleteKeychain} />
      <ConfirmDeleteEntity type="key" action={deleteKey} />
      <PageHeading icon="key" className="mb-4">
        {isNew ? `Create Keychain` : `Edit Keychain`}
      </PageHeading>
      <div className="mt-8 space-y-8">
        <div className="flex flex-col gap-8 border border-slate-200 p-6 lg:p-8 rounded-3xl bg-slate-100">
          <TextInput
            type="text"
            label="Name:"
            value={name}
            setValue={setName}
            className="max-w-3xl"
            name="name"
          />
          <TextInput
            type="textarea"
            rows={5}
            label="Description:"
            value={description}
            setValue={setDescription}
            className="max-w-3xl"
            name="description"
          />
        </div>
        <div>
          {keys.length > 0 ? (
            <>
              <div className="flex items-center justify-between rounded-b-none border border-slate-200 rounded-3xl bg-slate-100 px-8 py-4">
                <h2 className="text-lg font-bold text-slate-700">
                  {keys.length} {inflect(`key`, keys.length)}:
                </h2>
                <div className="flex items-center space-x-4">
                  <span className="text-slate-500">List view</span>
                  <Toggle
                    enabled={viewMode === 'table'}
                    setEnabled={() =>
                      setViewMode(viewMode === 'table' ? 'list' : 'table')
                    }
                  />
                  <span className="text-slate-500">Table view</span>
                </div>
              </div>
              <KeyList
                viewMode={viewMode}
                keys={keys}
                editKey={beginEditKey}
                deleteKey={(id) => deleteKey.start(id)}
              />
              <div className="mt-4 flex justify-end">
                <Button color="secondary" type="button" onClick={onCreateNewKey}>
                  <i className="fa-solid fa-plus mr-2" />
                  Add new key
                </Button>
              </div>
            </>
          ) : (
            !isNew && (
              <EmptyState
                heading="No keys"
                secondaryText="Add a key to this keychain:"
                icon="key"
                buttonText="Create key"
                action={onCreateNewKey}
              />
            )
          )}
        </div>
        <div className="flex mt-5 justify-end border-t-2 pt-8 space-x-5">
          {!isNew && (
            <Button type="button" onClick={deleteKeychain.start} color="warning">
              Delete keychain
            </Button>
          )}
          <Button
            type="button"
            disabled={saveButtonDisabled}
            onClick={onSave}
            color="primary"
          >
            {isNew ? `Create` : `Save`} keychain
          </Button>
        </div>
      </div>
    </div>
  );
};

export default EditKeychain;
