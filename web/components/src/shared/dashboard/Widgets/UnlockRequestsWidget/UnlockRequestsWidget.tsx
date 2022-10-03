import React from 'react';
import cx from 'classnames';
import DashboardWidget from '../DashboardWidget';
import Button from '../../../Button';
import UnlockRequestCard from '../../UnlockRequestCard';
import { inflect } from '../../lib/string';

type Props = {
  className?: string;
  unlockRequests: { url: string; user: string; comment?: string; time: Date }[];
};

const UnlockRequestsWidget: React.FC<Props> = ({ className, unlockRequests }) => (
  <DashboardWidget inset className={className}>
    {unlockRequests
      .sort((a, b) => b.time.getTime() - a.time.getTime())
      .slice(0, 2)
      .map((req) => (
        <UnlockRequestCard
          key={req.time.toISOString()} // this will need to change to the id or something
          userName={req.user}
          comment={req.comment}
          time={req.time}
          url={req.url}
        />
      ))}
    {unlockRequests.length > 2 && (
      <div className="flex flex-col items-center mb-3">
        <h3 className="text-gray-500 font-medium">
          And {unlockRequests.length - 2} older{` `}
          {inflect(`request`, unlockRequests.length - 2)}:
        </h3>
        <Button
          type="button"
          onClick={() => {}}
          color="secondary-white"
          small
          className="mt-3"
        >
          View all
        </Button>
      </div>
    )}
  </DashboardWidget>
);

export default UnlockRequestsWidget;
