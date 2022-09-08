import React, { ComponentProps } from 'react';
import { posessive } from '../../../../lib/string';
import PartyMessage from '../../../../PartyMessage';
import PageHeading from '../../../PageHeading';
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
      <div className="my-8 space-y-6 sm:space-y-10">
        {days.map((day) => (
          <ReviewSummaryCard key={`${day.date}`} {...day} />
        ))}
      </div>
    ) : (
      <PartyMessage>Nothing to review from the last two weeks</PartyMessage>
    )}
  </>
);

export default UserActivityOverviewScreen;
