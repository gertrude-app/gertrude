import {
  Button,
  ConfirmationDialog,
  DateTimePicker,
  SlideOver,
  Spacer,
  Text,
  Textarea,
  VStack,
} from '@gertrude/ui';
import { KeyRoundIcon, TrashIcon } from 'lucide-react';
import React from 'react';
import type { KeychainKey } from '#/components/types';
import type { KeyEditorApp, KeyEditorSaveData, KeyEditorState } from './keyEditor';
import KeyScopeEditor from './KeyScopeEditor';
import KeyTargetEditor from './KeyTargetEditor';
import {
  broadAccessWarning,
  changeKeyEditorAddress,
  changeKeyEditorDomainMatch,
  changeKeyEditorTargetType,
  keyEditorError,
  keyFromEditorState,
  keyToEditorState,
  newKeyEditorState,
} from './keyEditor';

type Props = {
  open: boolean;
  keyRecord: KeychainKey;
  apps: KeyEditorApp[];
  saving: boolean;
  deleting: boolean;
  onOpenChange: (open: boolean) => void;
  onSave: (data: KeyEditorSaveData) => Promise<void>;
  onDelete: () => Promise<void>;
};

export const EditKeySlideOver: React.FC<Props> = ({
  open,
  keyRecord,
  apps,
  saving,
  deleting,
  onOpenChange,
  onSave,
  onDelete,
}) => {
  const formId = React.useId();
  const targetInputId = React.useId();
  const [state, setState] = React.useState<KeyEditorState>(
    () => keyToEditorState(keyRecord) ?? newKeyEditorState(),
  );

  React.useEffect(() => {
    if (!open) {
      return;
    }
    const nextState = keyToEditorState(keyRecord);
    if (nextState) {
      setState(nextState);
    }
  }, [keyRecord, open]);

  const key = keyFromEditorState(state);
  const error = keyEditorError(state);
  const warning = broadAccessWarning(state);
  const disabled = saving || deleting;

  const handleSubmit = (event: React.FormEvent<HTMLFormElement>): void => {
    event.preventDefault();
    if (!key || disabled) {
      return;
    }

    const comment = state.comment.trim();
    void onSave({
      key,
      comment: comment || undefined,
      expiration: state.expiration,
    }).then(
      () => onOpenChange(false),
      () => undefined,
    );
  };

  return (
    <SlideOver
      open={open}
      onOpenChange={onOpenChange}
      ariaLabel="Edit key"
      heading="Edit key"
      subheading="Update what this key allows and where it works."
      size="large"
      dismissible={!disabled}
    >
      <VStack className="h-full">
        <SlideOver.Body className="px-3 @lg/slide:px-6">
          <form id={formId} onSubmit={handleSubmit}>
            <VStack gap={6}>
              <KeyTargetEditor
                state={state}
                inputId={targetInputId}
                error={error}
                warning={warning}
                disabled={disabled}
                changeTargetType={(targetType) =>
                  setState((current) => changeKeyEditorTargetType(current, targetType))
                }
                changeAddress={(address) =>
                  setState((current) => changeKeyEditorAddress(current, address))
                }
                changeMatching={(domainMatch) =>
                  setState((current) => changeKeyEditorDomainMatch(current, domainMatch))
                }
              />

              <KeyScopeEditor
                state={state}
                apps={apps}
                disabled={disabled}
                changeScope={(scopeType) =>
                  setState((current) => ({ ...current, scopeType }))
                }
                changeAppIdentificationType={(appIdentificationType) =>
                  setState((current) => ({ ...current, appIdentificationType }))
                }
                changeAppSlug={(appSlug) =>
                  setState((current) => ({ ...current, appSlug }))
                }
                changeAppBundleId={(appBundleId) =>
                  setState((current) => ({ ...current, appBundleId }))
                }
              />

              <VStack gap={4}>
                <VStack gap={1}>
                  <Text as="h2" variant="heading">
                    Anything else?
                  </Text>
                  <Text variant="bodySubtle" className="leading-6">
                    Expiration and notes are optional.
                  </Text>
                </VStack>
                <DateTimePicker
                  label="Expiration"
                  date={state.expiration}
                  setDate={(expiration) =>
                    setState((current) => ({ ...current, expiration }))
                  }
                  notRequired
                  allowPast={false}
                />
                <Textarea
                  label="Note"
                  value={state.comment}
                  setValue={(comment) => setState((current) => ({ ...current, comment }))}
                  placeholder="Why this key is needed"
                  rows={3}
                  disabled={disabled}
                />
              </VStack>
            </VStack>
          </form>
        </SlideOver.Body>

        <SlideOver.Footer>
          <ConfirmationDialog
            confirmationQuestion="Delete this key?"
            description="Assigned Macs will stop allowing this address through this key."
            trigger={
              <Button
                type="button"
                variant="destructive"
                icon={TrashIcon}
                onClick={() => {}}
                disabled={disabled}
              >
                Delete
              </Button>
            }
            actions={[
              { text: `Cancel`, variant: `ghost` },
              {
                text: `Delete key`,
                variant: `destructive`,
                icon: TrashIcon,
                loading: deleting,
                onClick: () =>
                  onDelete().then(
                    () => onOpenChange(false),
                    () => undefined,
                  ),
              },
            ]}
          />
          <Spacer />
          <Button
            type="button"
            variant="ghost"
            onClick={() => onOpenChange(false)}
            disabled={disabled}
          >
            Cancel
          </Button>
          <Button
            type="submit"
            form={formId}
            variant="primary"
            icon={KeyRoundIcon}
            disabled={!key || disabled}
            loading={saving}
          >
            Save changes
          </Button>
        </SlideOver.Footer>
      </VStack>
    </SlideOver>
  );
};

export default EditKeySlideOver;
