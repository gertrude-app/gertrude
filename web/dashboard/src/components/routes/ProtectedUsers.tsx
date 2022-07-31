import DashboardPageHeading from '@shared/DashboardPageHeading';
import React from 'react';
import DashboardChrome from '../DashboardChrome';

const ProtectedUsers: React.FC = () => {
  return (
    <DashboardChrome>
      <div className="py-10 px-5 sm:px-10 lg:px-12 xl:px-16">
        <DashboardPageHeading icon="users">Protected users</DashboardPageHeading>
      </div>
    </DashboardChrome>
  );
};

export default ProtectedUsers;
