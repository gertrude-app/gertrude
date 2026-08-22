import {
  Badge,
  Banner,
  Card,
  EmptyState,
  HStack,
  PageHeading,
  Skeleton,
  VStack,
} from '@gertrude/ui';
import { CircleAlertIcon, PlusIcon, RefreshCwIcon, UsersIcon } from 'lucide-react';
import React from 'react';
import type { KeyEditorSaveData } from '#/components/keychains/keyEditor';
import type { KeychainDetail, KeychainKey, LoadableState } from '#/components/types';
import CreateKeySlideOver from '#/components/keychains/CreateKeySlideOver';
import EditKeySlideOver from '#/components/keychains/EditKeySlideOver';
import KeyList from '#/components/keychains/KeyList';
import CardContainer from '#/components/layout/CardContainer';
import DashboardPage from '#/components/layout/DashboardPage';

interface Props {
  state: LoadableState<KeychainDetail>;
  savingKey?: boolean;
  deletingKey?: boolean;
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
  savingKey = false,
  deletingKey = false,
  onSaveKey,
  onDeleteKey,
}) => {
  const [editorOpen, setEditorOpen] = React.useState(false);
  const [editingKey, setEditingKey] = React.useState<KeychainKey>();

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
          {keychain.isPublic && (
            <HStack>
              <Badge color="green" size="small" icon={UsersIcon}>
                Public keychain
              </Badge>
            </HStack>
          )}
          {keychain.warning && <Banner variant="warning">{keychain.warning}</Banner>}
          <CardContainer>
            <KeyList
              keys={keychain.keys}
              onEdit={keychain.isPublic ? undefined : openExistingKeyEditor}
            />
          </CardContainer>
        </VStack>
      </DashboardPage>
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
