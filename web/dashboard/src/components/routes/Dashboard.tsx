import React from 'react';
import WidgetsContainer from '@shared/dashboard/Widgets/WidgetsContainer';

const Dashboard: React.FC = () => {
  const now = new Date();
  return (
    <div className="">
      <WidgetsContainer
        unlockRequests={[
          {
            url: `gitlab.io`,
            user: `Little Jimmy`,
            comment: `Super cool thing I want`,
            time: new Date(now.getTime() - 0), // now
          },
          {
            url: `goats.com`,
            user: `Henry`,
            time: new Date(now.getTime() - 1000 * 120), // 2 minutes ago
          },
          {
            url: `github.com`,
            user: `Little Jimmy`,
            time: new Date(now.getTime() - 1000 * 60 * 60 * 24), // 1 day ago
          },
          {
            url: `magicschoolbus.com`,
            user: `Sally`,
            comment: `For science class, thanks ❤️`,
            time: new Date(now.getTime() - 1000 * 60 * 60 * 24 * 7 * 2), // 2 weeks ago
          },
        ]}
        users={[
          { name: `Little Jimmy`, online: true },
          { name: `Sally`, online: true },
          { name: `Henry`, online: false },
        ]}
      />
    </div>
  );
};

export default Dashboard;
