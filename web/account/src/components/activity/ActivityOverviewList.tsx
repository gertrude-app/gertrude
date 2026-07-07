import { Badge, Card, HStack, Text, VStack, inflect } from '@gertrude/ui';
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
        <Text variant="bodyMuted" className="text-center">
          {emptyText}
        </Text>
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
        <Text variant="captionMuted" className="text-center">
          Items from before {formatDate(oldestDate, `short`)} have been automatically
          deleted.
        </Text>
      )}
    </>
  );
};

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
    <Card
      as="a"
      href={href}
      padding={3}
      className="relative transition-[border-color,box-shadow] duration-100 hover:border-stone-300 hover:shadow-stone-400/60"
    >
      <DayCardBody date={date} stats={stats} />
    </Card>
  );
};

const DayCardBody: React.FC<{ date: Date; stats: ActivityReviewStats }> = ({
  date,
  stats,
}) => (
  <VStack>
    <Text variant="captionSubtle">{formatDate(date, `short`)}</Text>
    <HStack align="end" gap={1} className="mt-0.5">
      <Text variant="title">
        {stats.reviewedCount}/{stats.totalCount}
      </Text>
      <Text variant="bodySubtle" className="mb-0.5">
        {inflect(`item`, stats.totalCount)} reviewed
      </Text>
    </HStack>
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
  </VStack>
);

export default ActivityOverviewList;
