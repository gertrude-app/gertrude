import { Button, Input, Modal, Textarea, VStack } from '@gertrude/ui';
import React from 'react';

export type KeychainMetadata = {
  name: string;
  description?: string;
};

interface Props {
  keychain?: KeychainMetadata;
  saving: boolean;
  onClose: () => void;
  onSave: (data: KeychainMetadata) => Promise<void>;
}

const KeychainEditorModal: React.FC<Props> = ({ keychain, saving, onClose, onSave }) => {
  const formId = React.useId();
  const [name, setName] = React.useState(keychain?.name ?? ``);
  const [description, setDescription] = React.useState(keychain?.description ?? ``);
  const trimmedName = name.trim();
  const data: KeychainMetadata | null = trimmedName
    ? { name: trimmedName, description: description.trim() || undefined }
    : null;
  const changed =
    !keychain ||
    (data !== null &&
      (data.name !== keychain.name || data.description !== keychain.description));

  const submit = async (): Promise<void> => {
    if (!data || !changed || saving) return;
    try {
      await onSave(data);
      onClose();
    } catch {
      return;
    }
  };

  return (
    <Modal
      open
      onOpenChange={(open) => {
        if (!open && !saving) onClose();
      }}
      title={keychain ? `Edit keychain` : `Create keychain`}
      description="Give related keys a name so you can find and share them easily."
      size="small"
      dismissible={!saving}
      footer={
        <>
          <Button type="button" variant="ghost" disabled={saving} onClick={onClose}>
            Cancel
          </Button>
          <Button
            type="submit"
            form={formId}
            variant="primary"
            disabled={!data || !changed || saving}
            loading={saving}
          >
            {keychain ? `Save changes` : `Create keychain`}
          </Button>
        </>
      }
    >
      <form
        id={formId}
        onSubmit={(event) => {
          event.preventDefault();
          void submit();
        }}
      >
        <VStack gap={4}>
          <Input
            type="text"
            label="Name"
            value={name}
            setValue={setName}
            placeholder="School websites"
            autoComplete="off"
            required
            disabled={saving}
            error={
              !data && name.length > 0 ? `Enter a name for this keychain.` : undefined
            }
          />
          <Textarea
            label="Description (optional)"
            value={description}
            setValue={setDescription}
            placeholder="What these keys are used for"
            rows={3}
            disabled={saving}
          />
        </VStack>
      </form>
    </Modal>
  );
};

export default KeychainEditorModal;
