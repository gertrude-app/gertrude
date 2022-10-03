import React from 'react';
import DashboardWidget from '../DashboardWidget';

type Props = {
  userActivity: { user: string; unreviewedItems: number }[];
};

const UserActivityWidget: React.FC<Props> = ({ userActivity }) => {
  console.log(userActivity);
  return (
    <DashboardWidget className="shadow-inner bg-gray-100">
      {userActivity
        .sort((a, b) => a.unreviewedItems - b.unreviewedItems)
        .map((activity) => (
          <div></div>
        ))}
    </DashboardWidget>
  );
};

export default UserActivityWidget;
