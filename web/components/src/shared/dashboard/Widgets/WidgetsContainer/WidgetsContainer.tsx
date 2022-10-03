import React from 'react';
import cx from 'classnames';
import { UndoMainPadding } from '../../Chrome/Chrome';
import DashboardWidget from '../DashboardWidget';
import QuickActionsWidget from '../QuickActionsWidget';
import UnlockRequestsWidget from '../UnlockRequestsWidget';
import UserOverviewWidget from '../UsersOverviewWidget';
import UserActivityWidget from '../UserActivityWidget';
import UserScreenshotsWidget from '../UserScreenshotsWidget';

type Props = {
  className?: string;
  unlockRequests: { url: string; user: string; comment?: string; time: Date }[];
  users: { name: string; online: boolean }[];
  userActivity: { user: string; unreviewedItems: number }[];
  userScreenshots: { userName: string; img: string; app: string; time: Date }[];
};

const WidgetsContainer: React.FC<Props> = ({
  className,
  unlockRequests,
  users,
  userActivity,
  userScreenshots,
}) => {
  console.log(userActivity);
  return (
    <UndoMainPadding
      className={cx(
        `min-h-screen grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-4 lg:gap-6 xl:gap-8 p-3 sm:p-6 md:p-10`,
        className,
      )}
    >
      <QuickActionsWidget className="xl:row-span-2" />
      <UserActivityWidget userActivity={userActivity} />
      {unlockRequests.length !== 0 && (
        <UnlockRequestsWidget
          className="row-span-2 xl:row-span-3"
          unlockRequests={unlockRequests}
        />
      )}
      <UserScreenshotsWidget
        userScreenshots={userScreenshots}
        className="xl:row-span-2"
      />
      <UserOverviewWidget users={users} />
    </UndoMainPadding>
  );
};

export default WidgetsContainer;
