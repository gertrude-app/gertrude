import React from 'react';
import { Button } from '@shared/components';
import { Api } from '@dash/types';
import { writable, newestFirst, inflect } from '@dash/utils';
import type { DashboardWidgetData } from '@dash/types';
import UnlockRequestCard from '../UnlockRequestCard';
import DashboardWidget from './DashboardWidget';
import WidgetTitle from './WidgetTitle';

type Props = {
  className?: string;
  unlockRequests: DashboardWidgetData['unlockRequests'];
};

const UnlockRequestsWidget: React.FC<Props> = ({ className, unlockRequests }) => (
  <DashboardWidget inset className={className}>
    <WidgetTitle icon="unlock" text="Unlock requests" />
    <div className="space-y-5">
      {writable(unlockRequests)
        .sort(newestFirst)
        .slice(0, 2)
        .map((req) => (
          <UnlockRequestCard
            key={req.id}
            id={req.id}
            userName={req.userName}
            comment={req.comment ?? undefined}
            status={Api.RequestStatus.pending}
            createdAt={req.createdAt}
            url={req.target}
          />
        ))}
    </div>
    {unlockRequests.length > 2 && (
      <div className="mt-8 flex flex-col items-center mb-3">
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
