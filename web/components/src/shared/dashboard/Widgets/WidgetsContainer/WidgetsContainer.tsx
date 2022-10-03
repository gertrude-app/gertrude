import React from 'react';
import cx from 'classnames';
import { UndoMainPadding } from '../../Chrome/Chrome';
import QuickActionsWidget from '../QuickActionsWidget';
import UnlockRequestsWidget from '../UnlockRequestsWidget';
import UserOverviewWidget from '../UsersOverviewWidget';
import UserActivityWidget from '../UserActivityWidget';
import UserScreenshotsWidget from '../UserScreenshotsWidget';

type Props = {
  className?: string;
  unlockRequests: { url: string; user: string; comment?: string; time: Date }[];
  users: { name: string; online: boolean }[];
  userActivity: { user: string; unreviewedItems: number }[];
  userScreenshots: { userName: string; img: string; app: string; time: Date }[];
};

const WidgetsContainer: React.FC<Props> = ({
  className,
  unlockRequests,
  users,
  userActivity,
  userScreenshots,
}) => {
  if (users.length > 0)
    return (
      <UndoMainPadding
        className={cx(
          `min-h-screen grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-4 lg:gap-6 xl:gap-8 p-3 sm:p-6 md:p-10`,
          className,
        )}
      >
        <QuickActionsWidget className="xl:row-span-2" />
        <UserActivityWidget userActivity={userActivity} />
        {unlockRequests.length !== 0 && (
          <UnlockRequestsWidget
            className="row-span-2 xl:row-span-3"
            unlockRequests={unlockRequests}
          />
        )}
        <UserScreenshotsWidget
          userScreenshots={userScreenshots}
          className="xl:row-span-2"
        />
        <UserOverviewWidget users={users} />
      </UndoMainPadding>
    );
  return (
    <UndoMainPadding className="w-full h-screen flex justify-center items-center sm:p-10">
      <div className="flex justify-center items-center flex-col p-8 lg:p-16 bg-white shadow-xl rounded-2xl relative left-4">
        <h1 className="text-center text-3xl font-inter text-gray-900">
          Welcome to Gertrude!
        </h1>
        <p className="text-center sm:text-lg text-gray-500 mt-3 max-w-xl">
          It looks like you're new around here; that's great! Here's what we recommend to
          get started:
        </p>
        <div className="mt-8 space-y-3">
          <RecommendedStep
            onClick={() => {}}
            title="Download a copy of the macOS app"
            icon="download"
          />
          <RecommendedStep
            onClick={() => {}}
            title="Create a user for someone you want to protect"
            icon="user-plus"
          />
          <RecommendedStep
            onClick={() => {}}
            title="Create a device for that user"
            icon="computer"
          />
        </div>
      </div>
    </UndoMainPadding>
  );
};

export default WidgetsContainer;

interface RecommendedStepProps {
  title: string;
  icon: string;
  onClick(): void;
}

export const RecommendedStep: React.FC<RecommendedStepProps> = ({
  title,
  icon,
  onClick,
}) => {
  return (
    <div
      className="flex items-center p-4 pr-8 bg-gray-50 rounded-2xl cursor-pointer transition duration-150 hover:bg-gray-100 hover:scale-105"
      onClick={onClick}
    >
      <div className="bg-gradient-to-br from-indigo-500 to-fuchsia-500 w-14 h-14 flex justify-center items-center rounded-xl shrink-0">
        <i className={`fa-solid fa-${icon} text-white text-xl`} />
      </div>
      <h2 className="ml-4 sm:text-lg font-medium">{title}</h2>
    </div>
  );
};
