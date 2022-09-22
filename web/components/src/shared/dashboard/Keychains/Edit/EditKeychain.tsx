import React from 'react';
import Button from '../../../Button';
import { inflect } from '../../lib/string';
import { ConfirmableEntityAction } from '../../../types';
import Modal, { ConfirmDeleteEntity } from '../../Modal';
import PageHeading from '../../PageHeading';
import TextInput from '../../TextInput';
import KeyCreator from '../Keys/KeyCreator';
import * as EditKey from '../../lib/keys/edit';

type Props = {
  isNew: boolean;
  name: string;
  description: string;
  setName(name: string): unknown;
  setDescription(description: string): unknown;
  deleteKeychain: ConfirmableEntityAction<void>;
  keys: Array<{ id: UUID }>;
  saveButtonDisabled: boolean;
  onSave(): unknown;
  editingKey?: EditKey.State;
  updateEditingKey(event: EditKey.Event): unknown;
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
}) => (
  <div className="relative max-w-3xl">
    <Modal
      type="container"
      title="Create a new key"
      isOpen={!!editingKey}
      icon="key"
      primaryButtonText="Create key"
      onPrimaryClick={() => {}}
      onDismiss={() => {}}
    >
      <KeyCreator
        update={updateEditingKey}
        {...editingKey!}
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
        {keys.map((key) => (
          <div key={key.id} className="flex items-center justify-between">
            Key: <pre className="text-fuchsia-700">{key.id}</pre>
          </div>
        ))}
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
