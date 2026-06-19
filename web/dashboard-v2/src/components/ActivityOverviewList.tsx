import { Badge, inflect } from '@gertrude/ui';
import { Link } from '@tanstack/react-router';
import React from 'react';
import type { ActivityItem } from '#/lib/mock';
import CardContainer from '#/components/CardContainer';
import { type ActivityReviewStats, getActivityReviewStats } from '#/lib/activity-helpers';
import { formatDate, groupBy } from '#/lib/utils';

interface Props {
  activities: ActivityItem[];
  dayHref: (date: Date) => string;
  emptyText?: string;
}

const ActivityOverviewList: React.FC<Props> = ({
  activities,
  dayHref,
  emptyText = `No activity to review.`,
}) => {
  const activityByDate = groupBy(activities, (activity) => activity.date.toDateString());
  const oldestDate = activities.at(-1)?.date;

  if (activities.length === 0) {
    return (
      <CardContainer className="flex flex-col gap-4">
        <span className="text-center text-sm text-stone-500">{emptyText}</span>
      </CardContainer>
    );
  }

  return (
    <>
      <CardContainer className="flex flex-col gap-4">
        {Array.from(activityByDate.entries()).map(([dateString, dayActivities]) => {
          const date = new Date(dateString);
          const stats = getActivityReviewStats(dayActivities);

          return (
            <ActivityOverviewDayCard
              key={dateString}
              date={date}
              href={dayHref(date)}
              stats={stats}
            />
          );
        })}
      </CardContainer>
      {oldestDate && (
        <span className="text-center text-sm text-stone-400">
          Items from before {formatDate(oldestDate)} have been automatically deleted.
        </span>
      )}
    </>
  );
};

interface ActivityOverviewDayCardProps {
  date: Date;
  href: string;
  stats: ActivityReviewStats;
}

const ActivityOverviewDayCard: React.FC<ActivityOverviewDayCardProps> = ({
  date,
  href,
  stats,
}) => (
  <Link
    to={href}
    className="border border-stone-200 bg-white rounded-xl shadow shadaw-stone-300/30 relative flex flex-col p-3 hover:border-stone-300 hover:shadow-stone-400/60 transition-[border-color,box-shadow] duration-100"
  >
    <span className="text-xs text-stone-600">{formatDate(date)}</span>
    <span className="flex items-end gap-1 mt-0.5">
      <span className="text-xl font-medium text-stone-900">
        {stats.reviewedCount}/{stats.totalCount}
      </span>
      <span className="text-sm text-stone-600 mb-0.5">
        {inflect(`item`, stats.totalCount)} reviewed
      </span>
    </span>
    <div className="h-2 w-full bg-stone-200/70 rounded-full relative overflow-hidden mt-4">
      <div
        className="h-full bg-violet-400"
        style={{ width: `${stats.reviewedPercent}%` }}
      />
    </div>
    {stats.flaggedCount > 0 && (
      <Badge size="small" color="yellow" className="absolute top-3 right-3">
        {stats.flaggedCount} flagged
      </Badge>
    )}
  </Link>
);

export default ActivityOverviewList;
