import {
  Badge,
  Banner,
  Button,
  Card,
  ConfirmationDialog,
  EmptyState,
  HStack,
  PageHeading,
  Skeleton,
  Text,
  VStack,
} from '@gertrude/ui';
import {
  CircleAlertIcon,
  PencilIcon,
  PlusIcon,
  RefreshCwIcon,
  TrashIcon,
  UsersIcon,
} from 'lucide-react';
import React from 'react';
import type { KeychainMetadata } from '#/components/keychains/KeychainEditorModal';
import type { KeyEditorSaveData } from '#/components/keychains/keyEditor';
import type {
  AssignablePerson,
  KeychainDetail,
  KeychainKey,
  LoadableState,
} from '#/components/types';
import CreateKeySlideOver from '#/components/keychains/CreateKeySlideOver';
import EditKeySlideOver from '#/components/keychains/EditKeySlideOver';
import KeyList from '#/components/keychains/KeyList';
import KeychainAssignmentMenu from '#/components/keychains/KeychainAssignmentMenu';
import KeychainEditorModal from '#/components/keychains/KeychainEditorModal';
import CardContainer from '#/components/layout/CardContainer';
import DashboardPage from '#/components/layout/DashboardPage';

interface Props {
  state: LoadableState<KeychainDetail>;
  people: AssignablePerson[];
  onAssignmentChange: (personId: string, assigned: boolean) => Promise<void>;
  savingKey?: boolean;
  deletingKey?: boolean;
  savingKeychain?: boolean;
  deletingKeychain?: boolean;
  onSaveKeychain: (data: KeychainMetadata) => Promise<void>;
  onDeleteKeychain: () => Promise<void>;
  onSaveKey: (keyId: string | undefined, data: KeyEditorSaveData) => Promise<void>;
  onDeleteKey: (keyId: string) => Promise<void>;
}

const breadcrumbs = [{ text: `Keychains`, href: `/keychains` }];

const KeychainDetailLoading: React.FC = () => (
  <DashboardPage heading={<PageHeading title="Keychain" breadcrumbs={breadcrumbs} />}>
    <CardContainer>
      <Card padding={0} className="overflow-hidden">
        <HStack
          justify="between"
          className="border-b border-stone-200 bg-stone-50/70 px-4 py-3"
        >
          <VStack gap={1}>
            <Skeleton className="h-5 w-16" />
            <Skeleton className="h-3.5 w-36" />
          </VStack>
        </HStack>
        {[0, 1, 2, 3].map((index) => (
          <div
            key={index}
            className="grid grid-cols-1 gap-3 border-b border-stone-200/70 px-3 py-4 last:border-b-0 @2xl/main:grid-cols-[minmax(0,1.35fr)_2rem_minmax(13rem,0.8fr)] @2xl/main:items-center @2xl/main:gap-4 @2xl/main:px-4"
          >
            <HStack align="start" gap={3}>
              <Skeleton radius="medium" className="h-8 w-8 shrink-0" />
              <VStack gap={1.5} className="min-w-0 flex-grow">
                <Skeleton className="h-4 w-3/5" />
                <Skeleton className="h-3.5 w-32" />
              </VStack>
            </HStack>
            <Skeleton className="hidden h-px w-full @2xl/main:block" />
            <VStack gap={1.5} className="pl-11 @2xl/main:pl-0">
              <Skeleton className="h-4 w-28" />
              <Skeleton className="h-3.5 w-44" />
            </VStack>
          </div>
        ))}
      </Card>
    </CardContainer>
  </DashboardPage>
);

const KeychainDetailError: React.FC<Extract<Props[`state`], { status: `error` }>> = ({
  message,
  onRetry,
}) => (
  <DashboardPage heading={<PageHeading title="Keychain" breadcrumbs={breadcrumbs} />}>
    <CardContainer>
      <div role="alert">
        <EmptyState
          icon={CircleAlertIcon}
          title="Couldn't load keychain"
          description={message}
          button={{
            text: `Try again`,
            type: `button`,
            onClick: onRetry,
            icon: RefreshCwIcon,
          }}
          className="bg-white"
        />
      </div>
    </CardContainer>
  </DashboardPage>
);

const KeychainDetailPage: React.FC<Props> = ({
  state,
  people,
  onAssignmentChange,
  savingKey = false,
  deletingKey = false,
  savingKeychain = false,
  deletingKeychain = false,
  onSaveKeychain,
  onDeleteKeychain,
  onSaveKey,
  onDeleteKey,
}) => {
  const [editorOpen, setEditorOpen] = React.useState(false);
  const [editingKey, setEditingKey] = React.useState<KeychainKey>();
  const [metadataOpen, setMetadataOpen] = React.useState(false);
  const [deleteOpen, setDeleteOpen] = React.useState(false);

  if (state.status === `loading`) {
    return <KeychainDetailLoading />;
  }

  if (state.status === `error`) {
    return <KeychainDetailError {...state} />;
  }

  const keychain = state.data;
  const openNewKeyEditor = (): void => {
    setEditingKey(undefined);
    setEditorOpen(true);
  };
  const openExistingKeyEditor = (key: KeychainKey): void => {
    setEditingKey(key);
    setEditorOpen(true);
  };
  const handleEditorOpenChange = (open: boolean): void => {
    setEditorOpen(open);
  };
  const deleteKeychain = async (): Promise<void> => {
    if (deletingKeychain) return;
    try {
      await onDeleteKeychain();
      setDeleteOpen(false);
    } catch {
      return;
    }
  };

  return (
    <>
      <DashboardPage
        heading={
          <PageHeading
            title={keychain.name}
            subtitle={keychain.description}
            breadcrumbs={breadcrumbs}
            buttons={
              keychain.isPublic
                ? undefined
                : [
                    {
                      text: `Edit keychain`,
                      icon: PencilIcon,
                      onClick: () => setMetadataOpen(true),
                    },
                    {
                      text: `Add key`,
                      variant: `primary`,
                      icon: PlusIcon,
                      onClick: openNewKeyEditor,
                    },
                  ]
            }
          />
        }
      >
        <VStack gap={4}>
          <HStack gap={3} wrap>
            {keychain.isPublic && (
              <Badge color="green" size="small" icon={UsersIcon}>
                Public keychain
              </Badge>
            )}
            <KeychainAssignmentMenu
              people={people}
              assignedPersonIds={keychain.assignedPeople.map(({ id }) => id)}
              onAssignmentChange={onAssignmentChange}
            />
          </HStack>
          {keychain.warning && <Banner variant="warning">{keychain.warning}</Banner>}
          <CardContainer>
            <KeyList
              keys={keychain.keys}
              onEdit={keychain.isPublic ? undefined : openExistingKeyEditor}
            />
          </CardContainer>
          {!keychain.isPublic && (
            <CardContainer
              heading="Danger zone"
              subheading="Permanently delete this keychain and all of its keys."
              dangerZone
              className="max-w-xl"
            >
              <ConfirmationDialog
                open={deleteOpen}
                onOpenChange={(open) => {
                  if (deletingKeychain) return;
                  setDeleteOpen(open);
                }}
                confirmationQuestion={`Delete ${keychain.name}?`}
                description={
                  <VStack gap={3}>
                    <Text variant="proseSubtle">
                      This will permanently delete the keychain and all its keys. This
                      cannot be undone.
                    </Text>
                    {keychain.assignedPeople.length > 0 && (
                      <Text variant="proseSubtle">
                        It will be removed from the Mac settings for{` `}
                        {keychain.assignedPeople.map(({ name }) => name).join(`, `)}.
                        Websites and apps allowed only by this keychain will stop being
                        allowed.
                      </Text>
                    )}
                  </VStack>
                }
                trigger={
                  <Button
                    type="button"
                    variant="destructive"
                    icon={TrashIcon}
                    className="mt-4"
                    onClick={() => {}}
                    disabled={savingKeychain || savingKey || deletingKey}
                    loading={deletingKeychain}
                  >
                    Delete keychain
                  </Button>
                }
                actions={[
                  { text: `Cancel` },
                  {
                    text: `Delete keychain`,
                    variant: `destructive`,
                    icon: TrashIcon,
                    disabled: savingKeychain || savingKey || deletingKey,
                    loading: deletingKeychain,
                    autoClose: false,
                    onClick: deleteKeychain,
                  },
                ]}
              />
            </CardContainer>
          )}
        </VStack>
      </DashboardPage>
      {!keychain.isPublic && metadataOpen && (
        <KeychainEditorModal
          keychain={keychain}
          saving={savingKeychain}
          onClose={() => setMetadataOpen(false)}
          onSave={onSaveKeychain}
        />
      )}
      {!keychain.isPublic &&
        (editingKey ? (
          <EditKeySlideOver
            open={editorOpen}
            keyRecord={editingKey}
            apps={keychain.apps}
            saving={savingKey}
            deleting={deletingKey}
            onOpenChange={handleEditorOpenChange}
            onSave={(data) => onSaveKey(editingKey.id, data)}
            onDelete={() => onDeleteKey(editingKey.id)}
          />
        ) : (
          <CreateKeySlideOver
            open={editorOpen}
            apps={keychain.apps}
            saving={savingKey}
            onOpenChange={handleEditorOpenChange}
            onSave={(data) => onSaveKey(undefined, data)}
          />
        ))}
    </>
  );
};

export default KeychainDetailPage;
