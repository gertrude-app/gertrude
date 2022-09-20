import React from 'react';
import Button from '../../../Button';
import { inflect } from '../../lib/string';
import { ConfirmableEntityAction } from '../../../types';
import { ConfirmDeleteEntity } from '../../Modal';
import PageHeading from '../../PageHeading';
import TextInput from '../../TextInput';

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
}) => (
  <div className="relative max-w-3xl">
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
