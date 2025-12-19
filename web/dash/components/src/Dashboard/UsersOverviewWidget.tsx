import { Button } from '@shared/components';
import cx from 'classnames';
import React from 'react';
import type { DashboardWidgets } from '@dash/types';
import UserStatus from '../UserStatus';
import DashboardWidget from './DashboardWidget';
import WidgetTitle from './WidgetTitle';

type Child = DashboardWidgets.Output[`children`][number];

type Props = {
  className?: string;
  users: Child[];
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
        <div className="flex flex-col gap-2 @container">
          {users.map((user) => (
            <UserStatus key={user.id} {...user} />
          ))}
        </div>
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
