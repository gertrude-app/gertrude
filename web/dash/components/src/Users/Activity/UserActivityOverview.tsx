import React from 'react';
import { posessive } from '@shared/string';
import type { ComponentProps } from 'react';
import PageHeading from '../../PageHeading';
import PartyMessage from '../../PartyMessage';
import ReviewSummaryCard from './DaySummaryCard';

type Props = {
  userName: string;
  days: Array<ComponentProps<typeof ReviewSummaryCard>>;
};

const UserActivityOverviewScreen: React.FC<Props> = ({ userName, days }) => (
  <>
    <PageHeading icon="user" className="mb-4 sm:mb-7">
      {posessive(userName)} Activity
    </PageHeading>
    {days.length > 0 ? (
      <div className="my-8">
        {days.map((day, index) => (
          <ReviewSummaryCard
            key={`${day.date}`}
            {...day}
            index={index}
            numDays={days.length}
          />
        ))}
      </div>
    ) : (
      <PartyMessage>Nothing to review from the last two weeks</PartyMessage>
    )}
  </>
);

export default UserActivityOverviewScreen;
