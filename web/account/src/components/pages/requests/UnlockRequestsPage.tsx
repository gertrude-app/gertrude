import { Card, EmptyState, HStack, Skeleton, Text } from '@gertrude/ui';
import { Link } from '@tanstack/react-router';
import {
  ChevronRightIcon,
  CircleAlertIcon,
  InboxIcon,
  RefreshCwIcon,
} from 'lucide-react';
import React from 'react';
import type { LoadableState } from '#/components/types';
import type { GetAccountUnlockRequestSummary } from '@shared/pairql/src/account';
import RequestsShellPage from './RequestsShellPage';
import CardContainer from '#/components/layout/CardContainer';

export type UnlockRequestSummaryState =
  LoadableState<GetAccountUnlockRequestSummary.Output>;

interface Props {
  state: UnlockRequestSummaryState;
  suspensionRequestCount?: number;
  refreshing?: boolean;
  onRefresh: () => void;
  reviewHrefForPerson: (personId: string) => string;
}

const LoadingState: React.FC = () => (
  <CardContainer className="flex flex-col gap-3">
    <span role="status" className="sr-only">
      Loading unlock requests
    </span>
    {[0, 1].map((index) => (
      <Card
        key={index}
        padding={3}
        className="grid grid-cols-[minmax(0,1fr)_auto] items-center gap-x-4 gap-y-1.5"
      >
        <HStack gap={2}>
          <Skeleton className="h-5 w-20" />
          <Skeleton radius="full" className="h-5 w-5" />
        </HStack>
        <HStack wrap gap={1.5} className="col-start-1 row-start-2">
          <Skeleton radius="medium" className="h-7 w-24" />
          <Skeleton radius="medium" className="h-7 w-32" />
        </HStack>
        <Skeleton className="col-start-2 row-span-2 row-start-1 h-5 w-5" />
      </Card>
    ))}
  </CardContainer>
);

const UnlockRequestsPage: React.FC<Props> = ({
  state,
  suspensionRequestCount,
  refreshing,
  onRefresh,
  reviewHrefForPerson,
}) => {
  let content: React.ReactNode;
  if (state.status === `loading`) {
    content = <LoadingState />;
  } else if (state.status === `error`) {
    content = (
      <CardContainer>
        <div role="alert">
          <EmptyState
            icon={CircleAlertIcon}
            title="Couldn't load unlock requests"
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
  } else if (state.data.people.length === 0) {
    content = (
      <CardContainer>
        <EmptyState
          icon={InboxIcon}
          title="No pending unlock requests"
          description="New requests will appear here when someone asks to use a blocked website or internet address."
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
  } else {
    content = (
      <CardContainer className="flex flex-col gap-3">
        {state.data.people.map((person) => (
          <Card
            as={Link}
            key={person.id}
            to={reviewHrefForPerson(person.id)}
            aria-label={`Review requests for ${person.name}`}
            interactive
            padding={3}
            className="grid grid-cols-[minmax(0,1fr)_auto] items-center gap-x-4 gap-y-1.5"
          >
            <HStack gap={2} className="min-w-0">
              <Text as="h2" variant="bodyLargeStrong" className="min-w-0 break-words">
                {person.name}
              </Text>
              <Text
                variant="caption"
                className="min-w-5 shrink-0 rounded-full bg-stone-100 px-1.5 text-center font-medium leading-5 tabular-nums !text-stone-600"
              >
                {person.pendingCount}
              </Text>
            </HStack>
            <HStack wrap gap={1.5} className="col-start-1 row-start-2 min-w-0">
              {person.targets.slice(0, 3).map((target) => (
                <Text
                  key={target}
                  variant="bodySubtle"
                  className="min-w-0 max-w-full rounded-md border border-stone-200 bg-stone-50 px-2 py-0.5 break-words"
                >
                  {target}
                </Text>
              ))}
              {person.targets.length > 3 && (
                <Text variant="captionMuted" className="whitespace-nowrap">
                  +{person.targets.length - 3} more
                </Text>
              )}
            </HStack>
            <ChevronRightIcon
              aria-hidden="true"
              className="col-start-2 row-span-2 row-start-1 h-5 w-5 text-stone-400"
            />
          </Card>
        ))}
      </CardContainer>
    );
  }

  return (
    <RequestsShellPage
      selected="unlock"
      unlockRequestCount={state.status === `success` ? state.data.totalCount : undefined}
      suspensionRequestCount={suspensionRequestCount}
    >
      {content}
    </RequestsShellPage>
  );
};

export default UnlockRequestsPage;
