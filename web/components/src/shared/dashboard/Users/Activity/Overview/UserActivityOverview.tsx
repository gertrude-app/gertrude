import React, { ComponentProps } from 'react';
import { posessive } from '../../../../lib/string';
import PartyMessage from '../../../../PartyMessage';
import ReviewSummaryCard from './DaySummaryCard';

type Props = {
  userName: string;
  days: Array<ComponentProps<typeof ReviewSummaryCard>>;
};

const UserActivityOverviewScreen: React.FC<Props> = ({ userName, days }) => (
  <>
    <h1 className="font-lato mb-4 sm:mb-7 text-2xl sm:text-3xl text-gray-700">
      {posessive(userName)} Activity
    </h1>
    {days.length > 0 ? (
      <div className="space-y-10">
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
