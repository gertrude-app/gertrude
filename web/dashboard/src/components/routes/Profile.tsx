import DashboardPageHeading from '@shared/DashboardPageHeading';
import TextInput from '@shared/TextInput';
import React from 'react';
import DashboardChrome from '../DashboardChrome';

const Profile: React.FC = () => {
  return (
    <DashboardChrome>
      <div className="py-10 px-20">
        <DashboardPageHeading icon="user">Profile</DashboardPageHeading>
      </div>
    </DashboardChrome>
  );
};

export default Profile;
