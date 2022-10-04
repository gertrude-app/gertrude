import React from 'react';
import cx from 'classnames';
import Button from '../../../Button';
import PillBadge from '../../PillBadge';
import DashboardWidget from '../DashboardWidget';

type Props = {
  className?: string;
  users: { name: string; online: boolean }[];
};

const UsersOverview: React.FC<Props> = ({ className, users }) => {
  if (users.length > 0)
    return (
      <DashboardWidget className={className}>
        {users.map((user) => (
          <UserOverview user={user} />
        ))}
      </DashboardWidget>
    );
  return (
    <DashboardWidget
      inset
      className={cx(
        `flex flex-col justify-center items-center p-6 bg-violet-50`,
        className,
      )}
    >
      <h3 className="font-bold text-black text-opacity-80 text-lg">No users</h3>
      <p className="mb-4 text-black text-opacity-50">Let's create one!</p>
      <Button type="link" color="primary-violet" to="/users/new" small>
        <i className="fa-solid fa-user-plus mr-2" /> Add user
      </Button>
    </DashboardWidget>
  );
};

export default UsersOverview;

interface UserOverviewProps {
  user: { name: string; online: boolean };
}

const UserOverview: React.FC<UserOverviewProps> = ({ user }) => {
  return (
    <div className="flex justify-between items-center rounded-xl py-4 px-4 even:bg-gray-50">
      <h3 className="font-medium text-gray-900">{user.name}</h3>
      {user.online ? (
        <PillBadge type="green">
          <i className="mr-2 fa-solid fa-circle text-green-500 text-sm scale-75" />
          Online
        </PillBadge>
      ) : (
        <PillBadge type="yellow">
          <i className="mr-2 fa-solid fa-circle text-yellow-500 text-sm scale-75" />
          Offline
        </PillBadge>
      )}
    </div>
  );
};
