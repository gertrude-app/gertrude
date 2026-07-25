import { Card, EmptyState, Skeleton, VStack } from '@gertrude/ui';
import { CircleAlertIcon, InboxIcon, RefreshCwIcon } from 'lucide-react';
import React from 'react';
import type { LoadableState, SuspensionRequest } from '#/components/types';
import RequestsShellPage from './RequestsShellPage';
import CardContainer from '#/components/layout/CardContainer';
import SuspensionRequestCard from '#/components/requests/SuspensionRequestCard';

export type SuspensionRequestsState = LoadableState<SuspensionRequest[]>;

interface Props {
  state: SuspensionRequestsState;
  refreshing?: boolean;
  onRefresh: () => void;
  responseHrefForRequest: (id: string) => string;
}

const RequestsLoadingState: React.FC = () => (
  <CardContainer className="grid grid-cols-1 gap-4 @3xl/main:grid-cols-2 @5xl/main:grid-cols-3">
    <span role="status" className="sr-only">
      Loading suspension requests
    </span>
    {[0, 1].map((index) => (
      <Card key={index} preset="big" padding={4}>
        <VStack gap={4}>
          <VStack gap={1.5}>
            <Skeleton className="h-5 w-24" />
            <Skeleton className="h-4 w-20" />
          </VStack>
          <Skeleton radius="large" className="h-20 w-full" />
          <Skeleton radius="medium" className="ml-auto h-7 w-36" />
        </VStack>
      </Card>
    ))}
  </CardContainer>
);

interface RequestsContentProps {
  state: SuspensionRequestsState;
  refreshing?: boolean;
  onRefresh: () => void;
  responseHrefForRequest: Props[`responseHrefForRequest`];
}

const RequestsContent: React.FC<RequestsContentProps> = ({
  state,
  refreshing,
  onRefresh,
  responseHrefForRequest,
}) => {
  if (state.status === `loading`) {
    return <RequestsLoadingState />;
  }

  if (state.status === `error`) {
    return (
      <CardContainer>
        <div role="alert">
          <EmptyState
            icon={CircleAlertIcon}
            title="Couldn't load suspension requests"
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
      </CardContainer>
    );
  }

  if (state.data.length === 0) {
    return (
      <CardContainer>
        <EmptyState
          icon={InboxIcon}
          title="No pending suspension requests"
          description="New requests will appear here when someone asks to pause filtering."
          button={{
            text: `Refresh`,
            type: `button`,
            onClick: onRefresh,
            icon: RefreshCwIcon,
            loading: refreshing,
          }}
          className="bg-white"
        />
      </CardContainer>
    );
  }

  return (
    <CardContainer className="grid grid-cols-1 gap-4 @3xl/main:grid-cols-2 @5xl/main:grid-cols-3">
      {state.data.map((request) => (
        <SuspensionRequestCard
          key={request.id}
          request={request}
          responseHref={responseHrefForRequest(request.id)}
        />
      ))}
    </CardContainer>
  );
};

const SuspensionRequestsPage: React.FC<Props> = ({
  state,
  refreshing,
  onRefresh,
  responseHrefForRequest,
}) => (
  <RequestsShellPage
    selected="suspension"
    suspensionRequestCount={state.status === `success` ? state.data.length : undefined}
  >
    <RequestsContent
      state={state}
      refreshing={refreshing}
      onRefresh={onRefresh}
      responseHrefForRequest={responseHrefForRequest}
    />
  </RequestsShellPage>
);

export default SuspensionRequestsPage;
