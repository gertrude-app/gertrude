import React from 'react';
import { Link } from 'react-router-dom';
import cx from 'classnames';
import { Button } from '@shared/components';
import { writable } from '@dash/utils';
import type { DashboardWidgets } from '@dash/types';
import DashboardWidget from './DashboardWidget';
import WidgetTitle from './WidgetTitle';

type Props = {
  userActivity: DashboardWidgets.Output['childActivitySummaries'];
  className?: string;
};

const UserActivityWidget: React.FC<Props> = ({ userActivity, className }) => {
  const caughtUp = userActivity.reduce(
    (acc, cur) => cur.numUnreviewed === 0 && acc,
    true,
  );
  if (userActivity.length === 0)
    return (
      <DashboardWidget className={cx(`!bg-violet-50`, className)}>
        <div className="flex flex-col justify-center items-center p-6 rounded-xl h-full">
          <h3 className="font-bold text-black text-opacity-80 text-lg text-center">
            No recorded child activity
          </h3>
          <p className="mb-4 text-violet-600/80 text-center">
            You can use Gertrude to monitor your childrens activity
          </p>
          <Button type="link" color="primary" to="/children">
            <i className="fa-solid fa-arrow-right mr-2" /> See how
          </Button>
        </div>
      </DashboardWidget>
    );
  if (caughtUp)
    return (
      <DashboardWidget className={cx(`flex justify-center items-center !p-4`, className)}>
        <div className="flex flex-col justify-center items-center bg-gradient-to-b from-violet-50 to-violet-100 h-full rounded-3xl p-8 flex-grow">
          <i className="fa-solid fa-mug-hot bg-gradient-to-br from-violet-200 to-violet-400 bg-clip-text [-webkit-background-clip:text;] text-transparent text-5xl" />
          <h2 className="text-xl font-black text-black text-opacity-90 mt-4 mb-1">
            You&rsquo;re all caught up!
          </h2>
          <p className="text-violet-600/80 text-center">
            No child activity items to review. Give yourself a pat on the back.
          </p>
        </div>
      </DashboardWidget>
    );

  return (
    <DashboardWidget className={cx(`!p-0 !sm:p-0 flex flex-col`, className)}>
      <div className="p-3 sm:p-4 pb-2 sm:pb-2 flex-grow">
        <WidgetTitle icon="binoculars" text="Activity" />
        <div className="mb-4 flex flex-col space-y-2">
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
        </div>
      </div>
      {userActivity.filter((a) => a.numUnreviewed > 0).length > 1 && (
        <div className="bg-violet-50/50 py-5 px-3 sm:px-4 rounded-b-3xl">
          <Button
            type="link"
            to="/children/activity"
            color="secondary"
            className=""
            size="large"
          >
            All activity
          </Button>
        </div>
      )}
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
    to={userId ? `/children/${userId}/activity` : `/children/activity`}
    className={cx(
      `ScrollTop rounded-xl border-[0.5px] p-4 flex justify-between items-center relative transition-[background-color] duration-100 cursor-pointer hover:bg-slate-50`,
      numUnreviewed === 0
        ? `bg-emerald-50 border-emerald-200 hover:!bg-emerald-100 hover:!bg-opacity-80`
        : `bg-slate-50/50 border-slate-100`,
      !userId && `bg-slate-100 hover:bg-slate-200 hover:bg-opacity-80`,
    )}
  >
    <h2 className="font-bold">{userName}</h2>
    <div className="flex flex-col items-end justify-center">
      <div className="flex items-center">
        {numUnreviewed === 0 && (
          <div className="w-5 h-5 bg-emerald-500 flex justify-center items-center rounded-full mr-2">
            <i className="fa-solid fa-check text-white text-sm" />
          </div>
        )}
        <h1 className="font-black text-xl">{numUnreviewed}</h1>
      </div>
      <p
        className={cx(
          `text-sm`,
          numUnreviewed === 0 ? `text-emerald-800/80` : `text-slate-500`,
        )}
      >
        unreviewed items
      </p>
    </div>
  </Link>
);
