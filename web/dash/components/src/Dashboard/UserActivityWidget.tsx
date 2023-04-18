import React from 'react';
import { Link } from 'react-router-dom';
import cx from 'classnames';
import { Button } from '@shared/components';
import { writable } from '@dash/utils';
import type { GetDashboardWidgets } from '@dash/types';
import DashboardWidget from './DashboardWidget';
import WidgetTitle from './WidgetTitle';

type Props = {
  userActivity: GetDashboardWidgets.Output['userActivitySummaries'];
  className?: string;
};

const UserActivityWidget: React.FC<Props> = ({ userActivity, className }) => {
  const caughtUp = userActivity.reduce(
    (acc, cur) => cur.numUnreviewed === 0 && acc,
    true,
  );
  if (userActivity.length === 0)
    return (
      <DashboardWidget className={cx(`bg-violet-50`, className)}>
        <div className="flex flex-col justify-center items-center p-6 rounded-xl h-full">
          <h3 className="font-bold text-black text-opacity-80 text-lg">
            No recorded user activity
          </h3>
          <p className="mb-4 text-black text-opacity-50 text-center">
            You can use Gertrude to monitor your users' activity
          </p>
          <Button type="link" color="primary" to="/users">
            <i className="fa-solid fa-arrow-right mr-2" /> See how
          </Button>
        </div>
      </DashboardWidget>
    );
  if (caughtUp)
    return (
      <DashboardWidget className={cx(`flex justify-center items-center p-4`, className)}>
        <div className="flex flex-col justify-center items-center bg-gradient-to-b from-violet-50 to-violet-100 h-full rounded-3xl p-8">
          <i className="fa-solid fa-mug-hot bg-gradient-to-br from-violet-200 to-violet-400 bg-clip-text [-webkit-background-clip:text;] text-transparent text-5xl" />
          <h2 className="text-xl font-black text-black text-opacity-90 mt-4 mb-1">
            You&rsquo;re all caught up!
          </h2>
          <p className="text-violet-600/80 text-center">
            No user activity items to review. Give yourself a pat on the back.
          </p>
        </div>
      </DashboardWidget>
    );

  return (
    <DashboardWidget className={cx(`space-y-3`, className)}>
      <WidgetTitle icon="binoculars" text="Activity" />

      {userActivity.filter((activity) => activity.numUnreviewed > 0).length > 1 && (
        <UnreviewedItemsCard
          userName={`All Activity`}
          numUnreviewed={userActivity.reduce(
            (acc, item) => (acc += item.numUnreviewed),
            0,
          )}
        />
      )}
      {writable(userActivity)
        .sort((a, b) => b.numUnreviewed - a.numUnreviewed)
        .map((activity) => (
          <UnreviewedItemsCard
            key={activity.id}
            userId={activity.id}
            userName={activity.name}
            numUnreviewed={activity.numUnreviewed}
          />
        ))}
    </DashboardWidget>
  );
};

export default UserActivityWidget;

interface UnreviewedItemsCardProps {
  userId?: UUID;
  userName: string;
  numUnreviewed: number;
}

export const UnreviewedItemsCard: React.FC<UnreviewedItemsCardProps> = ({
  userId,
  userName,
  numUnreviewed,
}) => (
  <Link
    to={userId ? `/users/${userId}/activity` : `/users/activity`}
    className={cx(
      `ScrollTop bg-white border rounded-xl p-4 flex justify-between items-center relative transition duration-100 cursor-pointer hover:bg-slate-50`,
      numUnreviewed === 0 && `bg-green-50 hover:bg-green-100 hover:bg-opacity-80`,
      !userId && `bg-slate-100 hover:bg-slate-200 hover:bg-opacity-80`,
    )}
  >
    <h2 className="font-bold">{userName}</h2>
    <div className="flex flex-col items-end justify-center">
      <div className="flex items-center">
        {numUnreviewed === 0 && (
          <div className="w-5 h-5 bg-green-400 flex justify-center items-center rounded-full mr-2">
            <i className="fa-solid fa-check text-white text-sm" />
          </div>
        )}
        <h1 className="font-black text-xl">{numUnreviewed}</h1>
      </div>
      <p className="text-sm text-slate-500">unreviewed items</p>
    </div>
  </Link>
);
