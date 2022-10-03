import React from 'react';
import cx from 'classnames';
import DashboardWidget from '../DashboardWidget';
import { relativeTime } from '../../lib/dates';

type Props = {
  className?: string;
  userScreenshots: { userName: string; img: string; app: string; time: Date }[];
};

const UserScreenshotsWidget: React.FC<Props> = ({ className, userScreenshots }) => (
  <DashboardWidget className={cx('', className)}>
    <div className="space-y-3">
      {userScreenshots.map((screenshot) => (
        <div className="p-2 pl-4 rounded-2xl flex justify-between items-center h-32 even:bg-gray-50">
          <div>
            <h3 className="font-bold">{screenshot.userName}</h3>
            <p className="text-sm text-gray-500 italic">
              {screenshot.app} • {relativeTime(screenshot.time)}
            </p>
          </div>
          <img
            src={screenshot.img}
            className="block rounded-lg w-32 sm:h-full sm:w-auto md:h-auto md:w-48 lg:w-40 xl:w-36 ml-2"
          />
        </div>
      ))}
    </div>
  </DashboardWidget>
);

export default UserScreenshotsWidget;
