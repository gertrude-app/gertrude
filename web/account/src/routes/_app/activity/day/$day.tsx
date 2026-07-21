import { LoadingDots, PageHeading } from '@gertrude/ui';
import { formatDate } from '@shared/datetime';
import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import ActivityFeed from '#/components/activity/ActivityFeed';
import DashboardPage from '#/components/layout/DashboardPage';
import {
  dateFromDayParam,
  dayRange,
  prepareDeleteCombined,
  prepareToggleFlagCombined,
  toCombinedActivityItems,
} from '#/lib/activity';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useMutation } from '#/pairql/mutation';
import { useOptimism, useQuery } from '#/pairql/query';

const NINE_MINUTES = 9 * 60 * 1000;

const ActivityDayPage: React.FC = () => {
  const { day } = Route.useParams();
  const navigate = Route.useNavigate();
  const queryKey = Key.dayActivity(day);
  const summariesKey = Key.activitySummaries;
  const optimistic = useOptimism();

  const query = useQuery(
    queryKey,
    () => liveClient.getDayActivity({ range: dayRange(day) }),
    { refetchInterval: NINE_MINUTES },
  );

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
    const [ids, next] = prepareToggleFlagCombined(id, query.data);
    optimistic.update(queryKey, next);
    toggleFlag.mutate({ ids });
  }

  function handleDelete(ids: string[]): void {
    if (!query.data) return;
    const [input, next] = prepareDeleteCombined(ids, query.data);
    if (input.keystrokeLineIds.length === 0 && input.screenshotIds.length === 0) return;
    optimistic.update(queryKey, next);
    deleteActivity.mutate(input, {
      onSuccess: () => {
        if (next.people.every((person) => person.items.length === 0)) {
          void navigate({ to: `/activity`, replace: true });
        }
      },
    });
  }

  function handleDeletePerson(personId: string): void {
    const person = query.data?.people.find((p) => p.personId === personId);
    if (person) handleDelete(person.items.map((item) => item.id));
  }

  return (
    <DashboardPage
      heading={
        <PageHeading
          title={formatDate(dateFromDayParam(day), `long`)}
          breadcrumbs={[{ text: `All Activity`, href: `/activity` }]}
        />
      }
    >
      {query.isPending ? (
        <LoadingDots />
      ) : query.isError ? (
        <p className="text-red-600">
          {query.error.userMessage ?? `Failed to load activity.`}
        </p>
      ) : (
        <ActivityFeed
          items={toCombinedActivityItems(query.data)}
          onToggleFlag={handleToggleFlag}
          onDelete={(id) => handleDelete([id])}
          onDeletePersonActivity={handleDeletePerson}
        />
      )}
    </DashboardPage>
  );
};

export const Route = createFileRoute(`/_app/activity/day/$day`)({
  component: ActivityDayPage,
});
