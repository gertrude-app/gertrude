import React from 'react';
import cx from 'classnames';
import { Button, Badge } from '@shared/components';
import type { GetDashboardWidgets } from '@dash/types';
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
      <DashboardWidget className={className}>
        <div className="flex items-center justify-between mb-3 sm:mb-4">
          <WidgetTitle icon="users" text="Children" className="!mb-0" />
          <Button type="link" to="/children" size="small" color="tertiary">
            All children
          </Button>
        </div>
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
      <h3 className="font-bold text-black text-opacity-80 text-lg">No children</h3>
      <p className="mb-4 text-black text-opacity-50">Let's add one!</p>
      <Button type="link" color="primary" to="/children/new">
        <i className="fa-solid fa-user-plus mr-2" /> Add child
      </Button>
    </DashboardWidget>
  );
};

export default UsersOverview;

const UserOverview: React.FC<User> = ({ status, name }) => (
  <div className="flex justify-between items-center rounded-xl py-4 px-4 even:bg-slate-50/50">
    <h3 className="font-medium text-slate-900">{name}</h3>
    {status.case !== `offline` ? (
      <Badge size="large" className="!px-4" type="green">
        <i className="mr-2 fa-solid fa-circle text-green-400 text-sm scale-50" />
        online
      </Badge>
    ) : (
      <Badge size="large" className="!px-4" type="yellow">
        <i className="mr-2 fa-solid fa-circle text-yellow-400 text-sm scale-50" />
        offline
      </Badge>
    )}
  </div>
);
