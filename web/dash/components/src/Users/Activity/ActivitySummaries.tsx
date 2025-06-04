import { posessive } from '@shared/string';
import React from 'react';
import type { ComponentProps } from 'react';
import EmptyState from '../../EmptyState';
import PageHeading from '../../PageHeading';
import DaySummaryCard from './DaySummaryCard';

type Props = {
  userName?: string;
  days: Array<ComponentProps<typeof DaySummaryCard>>;
};

const ActivitySummaries: React.FC<Props> = ({ userName, days }) => (
  <>
    <PageHeading icon={userName ? `user` : `users`} className="mb-4 sm:mb-7">
      {userName ? posessive(userName) : `All Child`} Activity
    </PageHeading>
    {days.length > 0 ? (
      <div className="my-8">
        {days.map((day, index) => (
          <DaySummaryCard
            key={`${day.date}`}
            {...day}
            index={index}
            numDays={days.length}
          />
        ))}
      </div>
    ) : (
      <EmptyState
        heading="No activity to review"
        secondaryText="No activity has been reported from this child in the past two weeks."
        icon="user"
        buttonText="Back to all children"
        buttonIcon="users"
        action="/children"
      />
    )}
  </>
);

export default ActivitySummaries;
