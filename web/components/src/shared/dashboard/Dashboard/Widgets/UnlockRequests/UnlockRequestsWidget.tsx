import React from 'react';
import DashboardWidget from '../DashboardWidget';
import Button from '../../../../Button';
import UnlockRequestCard from './UnlockRequestCard';
import { inflect } from '../../../lib/string';
import { writable } from '../../../lib/helpers';
import WidgetTitle from '../WidgetTitle';

type Props = {
  className?: string;
  unlockRequests: DashboardWidgetData['unlockRequests'];
};

const UnlockRequestsWidget: React.FC<Props> = ({ className, unlockRequests }) => (
  <DashboardWidget inset className={className}>
    <WidgetTitle icon="unlock" text="Unlock requests" />
    {writable(unlockRequests)
      .sort((a, b) => (b.createdAt > a.createdAt ? 1 : -1))
      .slice(0, 2)
      .map((req) => (
        <UnlockRequestCard
          key={req.id}
          userName={req.userName}
          comment={req.comment ?? undefined}
          createdAt={req.createdAt}
          url={req.target}
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
