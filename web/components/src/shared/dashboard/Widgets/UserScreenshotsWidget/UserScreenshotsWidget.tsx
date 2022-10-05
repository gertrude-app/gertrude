import React from 'react';
import cx from 'classnames';
import DashboardWidget from '../DashboardWidget';
import { relativeTime } from '../../lib/dates';

type Props = {
  className?: string;
  screenshots: DashboardWidgetData['userScreenshots'];
};

const UserScreenshotsWidget: React.FC<Props> = ({ className, screenshots }) => (
  <DashboardWidget className={cx(``, className)}>
    <div className="space-y-3">
      {screenshots.map((screenshot) => (
        <div
          key={screenshot.id}
          className="p-2 pl-4 rounded-2xl flex justify-between items-center h-32 even:bg-gray-50"
        >
          <div>
            <h3 className="font-bold">{screenshot.userName}</h3>
            <p className="text-sm text-gray-500 italic">
              {relativeTime(new Date(screenshot.createdAt))}
            </p>
          </div>
          <img
            src={screenshot.url}
            alt="User screenshot"
            className="block rounded-lg w-32 sm:h-full sm:w-auto md:h-auto md:w-48 lg:w-40 xl:w-36 ml-2"
          />
        </div>
      ))}
    </div>
  </DashboardWidget>
);

export default UserScreenshotsWidget;
