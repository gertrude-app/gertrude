import React from 'react';
import cx from 'classnames';
import { Button } from '@shared/components';
import type { GetDashboardWidgets } from '@dash/types';
import PillBadge from '../PillBadge';
import DashboardWidget from './DashboardWidget';
import WidgetTitle from './WidgetTitle';

type User = GetDashboardWidgets.Output['users'][number];

type Props = {
  className?: string;
  users: User[];
};

const UsersOverview: React.FC<Props> = ({ className, users }) => {
  if (users.length > 0)
    return (
      <DashboardWidget inset className={className}>
        <WidgetTitle icon="users" text="Users" />
        {users.map((user) => (
          <UserOverview key={user.id} {...user} />
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
      <Button type="link" color="primary" to="/users/new">
        <i className="fa-solid fa-user-plus mr-2" /> Add user
      </Button>
    </DashboardWidget>
  );
};

export default UsersOverview;

const UserOverview: React.FC<User> = ({ isOnline, name }) => (
  <div className="flex justify-between items-center rounded-xl py-4 px-4 even:bg-gray-50">
    <h3 className="font-medium text-gray-900">{name}</h3>
    {isOnline ? (
      <PillBadge type="green">
        <i className="mr-2 fa-solid fa-circle text-green-500 text-sm scale-75" />
        online
      </PillBadge>
    ) : (
      <PillBadge type="yellow">
        <i className="mr-2 fa-solid fa-circle text-yellow-500 text-sm scale-75" />
        offline
      </PillBadge>
    )}
  </div>
);
