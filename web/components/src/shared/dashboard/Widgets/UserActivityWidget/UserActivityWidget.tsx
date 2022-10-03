import React from 'react';
import cx from 'classnames';
import DashboardWidget from '../DashboardWidget';
import Button from '../../../Button';

type Props = {
  userActivity: { user: string; unreviewedItems: number }[];
};

const UserActivityWidget: React.FC<Props> = ({ userActivity }) => {
  const caughtUp = userActivity.reduce(
    (acc, cur) => cur.unreviewedItems === 0 && acc,
    true,
  );
  if (userActivity.length === 0)
    return (
      <DashboardWidget inset className="bg-violet-50">
        <div className="flex flex-col justify-center items-center p-6 rounded-xl h-full">
          <h3 className="font-bold text-black text-opacity-80 text-lg">
            No recorded user activity
          </h3>
          <p className="mb-4 text-black text-opacity-50 text-center">
            You can use Gertrude to monitor your users' activity
          </p>
          <Button type="link" color="primary-violet" to="/users/new" small>
            <i className="fa-solid fa-arrow-right mr-2" /> See how
          </Button>
        </div>
      </DashboardWidget>
    );
  if (caughtUp)
    return (
      <DashboardWidget
        inset
        className="bg-violet-50 flex flex-col justify-center items-center p-6"
      >
        <i className="fa-solid fa-mug-hot bg-gradient-to-br from-indigo-500 to-fuchsia-500 bg-clip-text text-transparent text-opacity-30 text-5xl" />
        <h2 className="text-xl font-black text-black text-opacity-90 mt-2 mb-1">
          You're all caught up!
        </h2>
        <p className="text-black text-opacity-60 text-center">
          No user activity items to review. Give yourself a pat on the back.
        </p>
      </DashboardWidget>
    );

  return (
    <DashboardWidget inset className="space-y-3">
      {userActivity
        .sort((a, b) => b.unreviewedItems - a.unreviewedItems)
        .map((activity) => (
          <UnreviewedItemsCard data={activity} />
        ))}
    </DashboardWidget>
  );
};

export default UserActivityWidget;

interface UnreviewedItemsCardProps {
  data: { user: string; unreviewedItems: number };
}

export const UnreviewedItemsCard: React.FC<UnreviewedItemsCardProps> = ({ data }) => {
  return (
    <div
      className={cx(
        `bg-white border shadow-lg rounded-xl p-4 flex justify-between items-center relative transition duration-100 cursor-pointer hover:bg-gray-50`,
        data.unreviewedItems === 0 &&
          `bg-green-50 hover:bg-green-100 hover:bg-opacity-80`,
      )}
    >
      <h2 className="font-bold">{data.user}</h2>
      <div className="flex flex-col items-end justify-center">
        <div className="flex items-center">
          {data.unreviewedItems === 0 && (
            <div className="w-5 h-5 bg-green-400 flex justify-center items-center rounded-full mr-2">
              <i className="fa-solid fa-check text-white text-sm" />
            </div>
          )}
          <h1 className="font-black text-xl">{data.unreviewedItems}</h1>
        </div>
        <p className="text-sm text-gray-500">unreviewed items</p>
      </div>
    </div>
  );
};
