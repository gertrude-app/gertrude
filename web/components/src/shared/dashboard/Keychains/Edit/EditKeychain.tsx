import React from 'react';
import Button from '../../../Button';
import { inflect } from '../../lib/string';
import { ConfirmableEntityAction } from '../../../types';
import Modal, { ConfirmDeleteEntity } from '../../Modal';
import PageHeading from '../../PageHeading';
import TextInput from '../../TextInput';
import KeyCreator from '../Keys/KeyCreator';
import * as EditKey from '../../lib/keys/edit';
import { target } from '../../lib/keys';

type Props = {
  isNew: boolean;
  name: string;
  description: string;
  setName(name: string): unknown;
  setDescription(description: string): unknown;
  deleteKeychain: ConfirmableEntityAction<void>;
  keys: KeyRecord[];
  saveButtonDisabled: boolean;
  onSave(): unknown;
  editingKey?: EditKey.State;
  beginEditKey(id: UUID): unknown;
  updateEditingKey(event: EditKey.Event): unknown;
  dismissEditKeyModal(): unknown;
  onKeySave(): unknown;
  onCreateNewKey(): unknown;
  keyModalSaveButtonDisabled: boolean;
};

const EditKeychain: React.FC<Props> = ({
  isNew,
  name,
  description,
  setName,
  setDescription,
  keys,
  deleteKeychain,
  saveButtonDisabled,
  onSave,
  editingKey,
  updateEditingKey,
  dismissEditKeyModal,
  onKeySave,
  beginEditKey,
  onCreateNewKey,
  keyModalSaveButtonDisabled,
}) => (
  <div className="relative max-w-3xl">
    <Modal
      type="container"
      title={editingKey?.isNew ? `Create a new key` : `Edit key`}
      isOpen={!!editingKey}
      contentHidden={!editingKey}
      icon="key"
      primaryButtonText={
        <>
          {editingKey?.isNew ? `Create` : `Save`} Key
          <i className="fa-solid fa-key ml-2" />
        </>
      }
      primaryButtonDisabled={keyModalSaveButtonDisabled}
      onPrimaryClick={onKeySave}
      onDismiss={dismissEditKeyModal}
    >
      {editingKey && (
        <KeyCreator
          update={updateEditingKey}
          {...editingKey}
          apps={[
            { slug: `slack`, name: `Slack` },
            { slug: `chrome`, name: `Chrome` },
            { slug: `figma`, name: `Figma` },
            { slug: `notes`, name: `Notes` },
            { slug: `firefox`, name: `Firefox` },
            { slug: `slug`, name: `Skype` },
            { slug: `vscode`, name: `Vscode` },
          ]}
        />
      )}
    </Modal>
    <ConfirmDeleteEntity type="keychain" action={deleteKeychain} />
    <PageHeading icon="key" className="mb-4">
      {isNew ? `Create Keychain` : `Edit Keychain`}
    </PageHeading>
    <div className="mt-8 space-y-8">
      <TextInput
        type="text"
        label="Name:"
        value={name}
        setValue={setName}
        className="max-w-xl"
      />
      <TextInput
        type="textarea"
        rows={5}
        label="Description:"
        value={description}
        setValue={setDescription}
      />
      <h2 className="mt-5 text-lg font-bold text-gray-700">
        {keys.length} {inflect(`key`, keys.length)}:
      </h2>
      <div>
        {keys.map((record) => (
          <div
            key={record.id}
            onClick={() => beginEditKey(record.id)}
            className="flex items-center justify-between"
          >
            {target(record.key)} <pre className="text-fuchsia-700">{record.id}</pre>
          </div>
        ))}
        <div className="mt-4 flex justify-end">
          <Button color="secondary-white" small type="button" onClick={onCreateNewKey}>
            <i className="fa-solid fa-plus mr-2" />
            Add new key
          </Button>
        </div>
      </div>
      <div className="flex mt-5 justify-end border-t-2 pt-8 space-x-5">
        {!isNew && (
          <Button
            type="button"
            onClick={deleteKeychain.start}
            color="secondary-warning"
            small
          >
            Delete keychain
          </Button>
        )}
        <Button
          small
          type="button"
          disabled={saveButtonDisabled}
          onClick={onSave}
          color="primary-violet"
        >
          {isNew ? `Create` : `Save`} keychain
        </Button>
      </div>
    </div>
  </div>
);

export default EditKeychain;
