import React from 'react';
import cx from 'classnames';
import { UndoMainPadding } from '../../Chrome/Chrome';
import DashboardWidget from '../DashboardWidget';
import QuickActionsWidget from '../QuickActionsWidget';
import UnlockRequestsWidget from '../UnlockRequestsWidget';
import UserOverviewWidget from '../UsersOverviewWidget';

type Props = {
  className?: string;
  unlockRequests: { url: string; user: string; comment?: string; time: Date }[];
  users: { name: string; online: boolean }[];
};

const WidgetsContainer: React.FC<Props> = ({ className, unlockRequests, users }) => (
  <UndoMainPadding
    className={cx(
      'min-h-screen grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-4 lg:gap-6 xl:gap-8 p-6 md:p-10',
      className,
    )}
  >
    <QuickActionsWidget className="xl:row-span-2" />
    <DashboardWidget>2</DashboardWidget>
    {unlockRequests.length !== 0 && (
      <UnlockRequestsWidget
        className="row-span-2 xl:row-span-3"
        unlockRequests={unlockRequests}
      />
    )}
    <DashboardWidget className="xl:row-span-2">4</DashboardWidget>
    <UserOverviewWidget users={users} />
  </UndoMainPadding>
);

export default WidgetsContainer;
