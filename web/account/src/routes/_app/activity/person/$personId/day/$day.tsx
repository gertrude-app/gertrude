import { PageHeading } from '@gertrude/ui';
import { formatDate } from '@shared/datetime';
import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import ActivityFeed from '#/components/activity/ActivityFeed';
import { ActivityFeedLoadingState } from '#/components/activity/ActivityLoadingStates';
import DashboardPage from '#/components/layout/DashboardPage';
import {
  dateFromDayParam,
  dayRange,
  prepareDelete,
  prepareToggleFlag,
  toActivityItems,
} from '#/lib/activity';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useMutation } from '#/pairql/mutation';
import { useOptimism, useQuery } from '#/pairql/query';

const NINE_MINUTES = 9 * 60 * 1000;

const PersonDayActivityPage: React.FC = () => {
  const { personId, day } = Route.useParams();
  const navigate = Route.useNavigate();
  const queryKey = Key.personDayActivity(personId, day);
  const optimistic = useOptimism();

  const query = useQuery(
    queryKey,
    () => liveClient.getPersonDayActivity({ personId, range: dayRange(day) }),
    { refetchInterval: NINE_MINUTES },
  );

  const summariesKey = Key.personActivitySummaries(personId);

  const toggleFlag = useMutation(liveClient.toggleActivityFlag, {
    invalidating: [queryKey, summariesKey],
    toast: {
      loading: `Updating activity…`,
      success: `Activity updated`,
      error: `Failed to update activity`,
    },
  });

  const deleteActivity = useMutation(liveClient.deleteActivity, {
    invalidating: [queryKey, summariesKey],
    toast: {
      loading: `Deleting activity…`,
      success: `Activity deleted`,
      error: `Failed to delete activity`,
    },
  });

  function handleToggleFlag(id: string): void {
    if (!query.data) return;
    const [ids, next] = prepareToggleFlag(id, query.data);
    optimistic.update(queryKey, next);
    toggleFlag.mutate({ ids });
  }

  function handleDelete(ids: string[]): void {
    if (!query.data) return;
    const [input, next] = prepareDelete(ids, query.data);
    if (input.keystrokeLineIds.length === 0 && input.screenshotIds.length === 0) return;
    optimistic.update(queryKey, next);
    deleteActivity.mutate(input, {
      onSuccess: () => {
        if (next.items.length === 0) {
          void navigate({
            to: `/activity/person/$personId`,
            params: { personId },
            replace: true,
          });
        }
      },
    });
  }

  function handleDeleteAll(): void {
    if (query.data) handleDelete(query.data.items.map((item) => item.id));
  }

  return (
    <DashboardPage
      heading={
        <PageHeading
          title={formatDate(dateFromDayParam(day), `long`)}
          breadcrumbs={[
            { text: `All Activity`, href: `/activity` },
            {
              text: query.data ? `${query.data.personName}'s Activity` : `Activity`,
              href: `/activity/person/${personId}`,
            },
          ]}
        />
      }
    >
      {query.isPending ? (
        <ActivityFeedLoadingState showPersonHeading={false} />
      ) : query.isError ? (
        <p className="text-red-600">
          {query.error.userMessage ?? `Failed to load activity.`}
        </p>
      ) : (
        <ActivityFeed
          items={toActivityItems(query.data, personId)}
          personName={query.data.personName}
          showPersonHeading={false}
          onToggleFlag={handleToggleFlag}
          onDelete={(id) => handleDelete([id])}
          onDeletePersonActivity={handleDeleteAll}
        />
      )}
    </DashboardPage>
  );
};

export const Route = createFileRoute(`/_app/activity/person/$personId/day/$day`)({
  component: PersonDayActivityPage,
});
