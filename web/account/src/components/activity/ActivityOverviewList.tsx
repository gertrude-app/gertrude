import { Badge, inflect } from '@gertrude/ui';
import { formatDate } from '@shared/datetime';
import React from 'react';
import type { ActivityReviewStats, DaySummary } from '#/lib/activity';
import CardContainer from '#/components/layout/CardContainer';

export type DayLinkTarget = { scope: `person`; personId: string } | { scope: `all` };

interface Props {
  days: DaySummary[];
  dayLink: DayLinkTarget;
  emptyText?: string;
}

const ActivityOverviewList: React.FC<Props> = ({
  days,
  dayLink,
  emptyText = `No activity to review.`,
}) => {
  if (days.length === 0) {
    return (
      <CardContainer className="flex flex-col gap-4">
        <span className="text-center text-sm text-stone-500">{emptyText}</span>
      </CardContainer>
    );
  }

  const oldestDate = days.at(-1)?.date;

  return (
    <>
      <CardContainer className="flex flex-col gap-4">
        {days.map(({ date, stats }) => (
          <ActivityOverviewDayCard
            key={date.toISOString()}
            dayLink={dayLink}
            date={date}
            stats={stats}
          />
        ))}
      </CardContainer>
      {oldestDate && (
        <span className="text-center text-sm text-stone-400">
          Items from before {formatDate(oldestDate, `short`)} have been automatically
          deleted.
        </span>
      )}
    </>
  );
};

const cardClassName =
  `border border-stone-200 bg-white rounded-xl shadow shadow-stone-300/30 relative flex flex-col p-3 ` +
  `hover:border-stone-300 hover:shadow-stone-400/60 transition-[border-color,box-shadow] duration-100`;

interface ActivityOverviewDayCardProps {
  dayLink: DayLinkTarget;
  date: Date;
  stats: ActivityReviewStats;
}

const ActivityOverviewDayCard: React.FC<ActivityOverviewDayCardProps> = ({
  dayLink,
  date,
  stats,
}) => {
  const day = formatDate(date, `dateInput`);
  const href =
    dayLink.scope === `person`
      ? `/activity/person/${dayLink.personId}/day/${day}`
      : `/activity/day/${day}`;

  return (
    <a href={href} className={cardClassName}>
      <DayCardBody date={date} stats={stats} />
    </a>
  );
};

const DayCardBody: React.FC<{ date: Date; stats: ActivityReviewStats }> = ({
  date,
  stats,
}) => (
  <>
    <span className="text-xs text-stone-600">{formatDate(date, `short`)}</span>
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
  </>
);

export default ActivityOverviewList;
