import React from 'react';
import { writable, newestFirst } from '@dash/utils';
import { relativeTime } from '@dash/datetime';
import type { GetDashboardWidgets } from '@dash/types';
import DashboardWidget from './DashboardWidget';
import WidgetTitle from './WidgetTitle';

type Props = {
  className?: string;
  screenshots: GetDashboardWidgets.Output['recentScreenshots'];
};

const UserScreenshotsWidget: React.FC<Props> = ({ className, screenshots }) => (
  <DashboardWidget className={className}>
    <WidgetTitle icon="clock" text="Recent screenshots" />
    <div className="space-y-3">
      {writable(screenshots)
        .sort(newestFirst)
        .map((screenshot) => (
          <div
            key={screenshot.id}
            className="p-2 pl-4 rounded-2xl flex justify-between items-center h-24 sm:h-32 even:bg-slate-50"
          >
            <div>
              <h3 className="font-bold">{screenshot.userName}</h3>
              <p className="text-sm text-slate-500 italic">
                {relativeTime(new Date(screenshot.createdAt))}
              </p>
            </div>
            <img
              src={screenshot.url}
              alt="Child screenshot"
              className="block rounded-lg w-32 sm:h-full sm:w-auto md:h-auto md:w-48 lg:w-40 xl:w-36 ml-2"
            />
          </div>
        ))}
    </div>
  </DashboardWidget>
);

export default UserScreenshotsWidget;
