import React from 'react';
import { DashboardWidgetData } from '@dash/types';
import { UndoMainPadding } from '../Chrome/Chrome';
import PageHeading from '../PageHeading';
import SmartLink from '../SmartLink';
import QuickActionsWidget from './QuickActionsWidget';
import UnlockRequestsWidget from './UnlockRequestsWidget';
import UserOverviewWidget from './UsersOverviewWidget';
import UserActivityWidget from './UserActivityWidget';
import UserScreenshotsWidget from './UserScreenshotsWidget';

type Props = {
  createKeychain: () => unknown;
} & DashboardWidgetData;

const Dashboard: React.FC<Props> = ({
  unlockRequests,
  users,
  userActivity,
  userScreenshots,
  createKeychain,
}) => {
  if (users.length > 0)
    return (
      <>
        <PageHeading icon="home">Dashboard</PageHeading>
        <div className="pt-6 grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-4 lg:gap-6 xl:gap-8">
          <UserActivityWidget userActivity={userActivity} />
          <UserOverviewWidget users={users} />
          <UserScreenshotsWidget
            screenshots={userScreenshots}
            className="xl:row-span-2 lg:-order-9"
          />
          {unlockRequests.length !== 0 && (
            <UnlockRequestsWidget
              className="row-span-2 xl:row-span-3 lg:-order-8"
              unlockRequests={unlockRequests}
            />
          )}
          <QuickActionsWidget
            createKeychain={createKeychain}
            className="xl:row-span-2 lg:-order-10"
          />
        </div>
      </>
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
            href="https://docs.gertrude.app"
            title="Read our getting started guide"
            icon="book"
          />
          <RecommendedStep
            href="https://gertrude.app/download"
            title="Download a copy of the macOS app"
            icon="download"
          />
          <RecommendedStep
            href="/users/new"
            title="Create a user for someone you want to protect"
            icon="user-plus"
          />
        </div>
      </div>
    </UndoMainPadding>
  );
};

export default Dashboard;

interface RecommendedStepProps {
  title: string;
  icon: string;
  href: string;
}

export const RecommendedStep: React.FC<RecommendedStepProps> = ({
  title,
  icon,
  href,
}) => (
  <SmartLink
    to={href}
    className="flex items-center p-4 pr-8 bg-gray-50 rounded-2xl cursor-pointer transition duration-150 hover:bg-gray-100 hover:scale-105"
  >
    <div className="bg-gradient-to-br from-indigo-500 to-fuchsia-500 w-14 h-14 flex justify-center items-center rounded-xl shrink-0">
      <i className={`fa-solid fa-${icon} text-white text-xl`} />
    </div>
    <h2 className="ml-4 sm:text-lg font-medium">{title}</h2>
  </SmartLink>
);
