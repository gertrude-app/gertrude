import { Button } from '@shared/components';
import React from 'react';
import type { DashboardWidgets_v3 } from '@dash/types';
import UserStatus from '../UserStatus';
import { consolidatedComputerStatus } from '../computerStatus';
import DashboardWidget from './DashboardWidget';
import WidgetTitle from './WidgetTitle';

type Child = DashboardWidgets_v3.Output[`children`][number];

type Props = {
  className?: string;
  users: Child[];
};

const UsersOverview: React.FC<Props> = ({ className, users }) => {
  const macUsers = users.filter((u) => u.devices.some((d) => d.macStatus));
  if (macUsers.length > 0)
    return (
      <DashboardWidget className={className}>
        <div className="flex items-center justify-between mb-3 sm:mb-4">
          <WidgetTitle icon="laptop" text="Macs" className="!mb-0" />
          <Button type="link" to="/children" size="small" color="tertiary">
            All children
          </Button>
        </div>
        <div className="flex flex-col gap-2 @container">
          {macUsers.map((user) => {
            const statuses = user.devices.flatMap((device) =>
              device.macStatus ? [device.macStatus] : [],
            );
            return (
              <UserStatus
                key={user.id}
                name={user.name}
                status={consolidatedComputerStatus(statuses)}
              />
            );
          })}
        </div>
      </DashboardWidget>
    );
  return null;
};

export default UsersOverview;
