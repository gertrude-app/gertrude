import { Card, EmptyState, PageHeading, Skeleton, VStack, toast } from '@gertrude/ui';
import { createFileRoute, useNavigate } from '@tanstack/react-router';
import { CircleAlertIcon, InboxIcon, RefreshCwIcon } from 'lucide-react';
import React from 'react';
import type { DecideUnlockRequests } from '@shared/pairql/src/account';
import DashboardPage from '#/components/layout/DashboardPage';
import UnlockRequestReviewPage from '#/components/pages/requests/UnlockRequestReviewPage';
import { apiEndpoint, liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useMutation } from '#/pairql/mutation';
import { useQuery } from '#/pairql/query';

const LoadingPage: React.FC = () => (
  <DashboardPage
    heading={
      <PageHeading
        title="Review unlock requests"
        breadcrumbs={[{ text: `Requests`, href: `/requests/unlock` }]}
      />
    }
  >
    <div className="mx-auto w-full max-w-5xl">
      <Card preset="big" padding={4}>
        <span role="status" className="sr-only">
          Loading unlock requests
        </span>
        <VStack gap={4}>
          <Skeleton className="h-6 w-48" />
          <Skeleton radius="large" className="h-28 w-full" />
          <Skeleton radius="large" className="h-28 w-full" />
        </VStack>
      </Card>
    </div>
  </DashboardPage>
);

const UnlockRequestReviewRoute: React.FC = () => {
  const { personId } = Route.useParams();
  const navigate = useNavigate();
  const query = useQuery(
    Key.personUnlockRequests(personId),
    () => liveClient.getPersonUnlockRequests({ personId }),
    { refetchInterval: 30_000 },
  );
  const mutation = useMutation(liveClient.decideUnlockRequests, {
    invalidating: [Key.unlockRequests, Key.personUnlockRequests(personId)],
    toast: {
      loading: `Submitting decisions...`,
      success: `Unlock request decisions submitted`,
      error: `Couldn't submit unlock request decisions`,
    },
    onSuccess: (output) => {
      if (output.skippedCount > 0) {
        toast.info(
          `${output.skippedCount} ${output.skippedCount === 1 ? `request was` : `requests were`} already handled and skipped.`,
        );
      }
      if (output.remainingCount === 0) {
        void navigate({ to: `/requests/unlock` });
      }
    },
  });

  if (query.data === undefined) {
    if (!query.isError) {
      return <LoadingPage />;
    }
    return (
      <DashboardPage
        heading={
          <PageHeading
            title="Review unlock requests"
            breadcrumbs={[{ text: `Requests`, href: `/requests/unlock` }]}
          />
        }
      >
        <div role="alert">
          <EmptyState
            icon={CircleAlertIcon}
            title="Couldn't load unlock requests"
            description={
              query.error.userMessage ?? `Check your connection and try again.`
            }
            button={{
              text: `Try again`,
              type: `button`,
              onClick: () => void query.refetch(),
              icon: RefreshCwIcon,
            }}
            className="bg-white"
          />
        </div>
      </DashboardPage>
    );
  }

  if (query.data.requests.length === 0) {
    return (
      <DashboardPage
        heading={
          <PageHeading
            title={`${query.data.personName}'s requests`}
            breadcrumbs={[{ text: `Requests`, href: `/requests/unlock` }]}
          />
        }
      >
        <EmptyState
          icon={InboxIcon}
          title="No pending unlock requests"
          description="These requests may already have been answered."
          button={{
            text: `Back to requests`,
            type: `link`,
            href: `/requests/unlock`,
          }}
          className="bg-white"
        />
      </DashboardPage>
    );
  }

  const submit = (
    decisions: DecideUnlockRequests.Input[`decisions`],
    responseComment?: string,
  ): void => {
    mutation.mutate({ personId, decisions, responseComment });
  };

  return (
    <UnlockRequestReviewPage
      key={query.data.requests.map((request) => request.id).join(`:`)}
      data={query.data}
      saving={mutation.isPending}
      appIconUrl={(hash) => `${apiEndpoint}/app-icon/${hash}`}
      onSubmit={submit}
      onRefresh={() => void query.refetch()}
    />
  );
};

export const Route = createFileRoute(`/_app/requests/unlock/$personId`)({
  component: UnlockRequestReviewRoute,
});
