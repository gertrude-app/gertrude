import React from 'react';
import { UndoMainPadding } from '../../Chrome/Chrome';
import DashboardWidget from '../DashboardWidget';
import QuickActionsWidget from '../QuickActionsWidget';
import UserOverviewWidget from '../UsersOverviewWidget';

type Props = {
  className?: string;
};

const WidgetsContainer: React.FC<Props> = ({ className }) => (
  <UndoMainPadding className="min-h-screen grid grid-cols-1 lg:grid-cols-2 xl:grid-rows-3 xl:grid-cols-3 gap-4 lg:gap-6 xl:gap-8 p-6 md:p-10">
    <QuickActionsWidget className="xl:row-span-2" />
    <DashboardWidget>2</DashboardWidget>
    <DashboardWidget className="row-span-2 xl:row-span-3">3</DashboardWidget>
    <DashboardWidget className="xl:row-span-2">4</DashboardWidget>
    <UserOverviewWidget
      users={[
        { name: 'Little Jimmy', online: true },
        { name: 'Sally', online: true },
        { name: 'Henry', online: false },
      ]}
    />
  </UndoMainPadding>
);

export default WidgetsContainer;
