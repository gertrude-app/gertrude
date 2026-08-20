import { Card, EmptyState, PageHeading, Skeleton, Text, VStack } from '@gertrude/ui';
import { CircleAlertIcon, KeyIcon, RefreshCwIcon } from 'lucide-react';
import React from 'react';
import type { KeychainsPageData, LoadableState } from '#/components/types';
import KeychainAssignmentMenu from '#/components/keychains/KeychainAssignmentMenu';
import KeychainCard from '#/components/keychains/KeychainCard';
import CardContainer from '#/components/layout/CardContainer';
import DashboardPage from '#/components/layout/DashboardPage';

interface Props {
  state: LoadableState<KeychainsPageData>;
  onAssignmentChange: (
    keychainId: string,
    personId: string,
    assigned: boolean,
  ) => Promise<void>;
}

const KeychainsLoadingState: React.FC = () => (
  <div className="grid grid-cols-1 gap-4 @3xl/main:grid-cols-2">
    {[0, 1, 2, 3].map((index) => (
      <Card key={index} padding={0} className="overflow-hidden">
        <Card.Body padding={3}>
          <VStack gap={2}>
            <Skeleton className="h-5 w-36" />
            <Skeleton className="h-4 w-4/5" />
          </VStack>
        </Card.Body>
        <Card.Footer className="flex items-center justify-between">
          <Skeleton className="h-3.5 w-12" />
          <Skeleton className="h-7 w-32" />
        </Card.Footer>
      </Card>
    ))}
  </div>
);

const KeychainsContent: React.FC<Props> = ({ state, onAssignmentChange }) => {
  if (state.status === `loading`) {
    return (
      <>
        <span role="status" className="sr-only">
          Loading keychains
        </span>
        <KeychainsLoadingState />
      </>
    );
  }

  if (state.status === `error`) {
    return (
      <div role="alert">
        <EmptyState
          icon={CircleAlertIcon}
          title="Couldn't load keychains"
          description={state.message}
          button={{
            text: `Try again`,
            type: `button`,
            onClick: state.onRetry,
            icon: RefreshCwIcon,
          }}
          className="bg-white"
        />
      </div>
    );
  }

  if (state.data.keychains.length === 0) {
    return (
      <EmptyState
        icon={KeyIcon}
        title="No keychains yet"
        description="No keychains have been created for this account."
        className="bg-white"
      />
    );
  }

  return (
    <div className="grid grid-cols-1 gap-4 @3xl/main:grid-cols-2">
      {state.data.keychains.map((keychain) => (
        <KeychainCard
          key={keychain.id}
          name={keychain.name}
          description={keychain.description}
          numKeys={keychain.numKeys}
          isPublic={keychain.isPublic}
          actions={
            <KeychainAssignmentMenu
              people={state.data.people}
              assignedPersonIds={keychain.assignedPersonIds}
              onAssignmentChange={(personId, assigned) =>
                onAssignmentChange(keychain.id, personId, assigned)
              }
            />
          }
        />
      ))}
    </div>
  );
};

const KeychainsPage: React.FC<Props> = (props) => (
  <DashboardPage
    heading={
      <PageHeading
        title="Keychains"
        subtitle="Group allowed websites and apps, then choose who can use them."
      />
    }
  >
    <VStack gap={4}>
      <Text variant="bodyMuted" className="max-w-3xl">
        Each keychain holds related keys that unlock parts of the internet on protected
        Macs.
      </Text>
      <CardContainer>
        <KeychainsContent {...props} />
      </CardContainer>
    </VStack>
  </DashboardPage>
);

export default KeychainsPage;
