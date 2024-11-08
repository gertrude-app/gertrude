import React from 'react';
import cx from 'classnames';
import type {
  CreatePendingAppConnection,
  GetDashboardWidgets,
  RequestState,
} from '@dash/types';
import { UndoMainPadding } from '../Chrome/Chrome';
import PageHeading from '../PageHeading';
import SmartLink from '../SmartLink';
import ConnectDeviceModal from '../Users/ConnectDeviceModal';
import AddDeviceInstructions from '../Users/AddDeviceInstructions';
import QuickActionsWidget from './QuickActionsWidget';
import UnlockRequestsWidget from './UnlockRequestsWidget';
import UserOverviewWidget from './UsersOverviewWidget';
import UserActivityWidget from './UserActivityWidget';
import UserScreenshotsWidget from './UserScreenshotsWidget';
import CreateFirstNotificationWidget from './CreateFirstNotificationWidget';

type Props = {
  date?: Date;
  startAddDevice: (userId: UUID) => void;
  dismissAddDevice: () => void;
  addDeviceRequest: RequestState<CreatePendingAppConnection.Output>;
} & GetDashboardWidgets.Output;

const Dashboard: React.FC<Props> = ({
  unlockRequests,
  users,
  userActivitySummaries,
  recentScreenshots,
  date = new Date(),
  startAddDevice,
  dismissAddDevice,
  addDeviceRequest,
  numAdminNotifications,
}) => {
  const hasNotifications = numAdminNotifications > 0;
  const firstUser = users[0];
  if (firstUser && users.reduce((acc, cur) => acc + cur.numDevices, 0) === 0) {
    return (
      <>
        <ConnectDeviceModal
          request={addDeviceRequest}
          dismissAddDevice={dismissAddDevice}
        />
        <UndoMainPadding className="flex justify-center items-center md:min-h-screen">
          <FloatingMessage className="flex flex-col items-center p-6 sm:p-8 lg:p-12 max-w-3xl">
            <AddDeviceInstructions
              userName={firstUser.name}
              userId={firstUser.id}
              startAddDevice={startAddDevice}
              onMainDashboard
            />
          </FloatingMessage>
        </UndoMainPadding>
      </>
    );
  }

  if (users.length > 0) {
    return (
      <>
        <PageHeading icon="home">Dashboard</PageHeading>
        <div className="pt-6 grid grid-cols-1 lg:grid-cols-2 2xl:grid-cols-3 gap-4 lg:gap-6 xl:gap-8">
          {!hasNotifications && <CreateFirstNotificationWidget className="-order-10" />}
          <UserActivityWidget userActivity={userActivitySummaries} />
          <UserOverviewWidget
            users={users}
            className={cx(!hasNotifications && `lg:col-span-2 2xl:col-span-1`)}
          />
          {recentScreenshots.length !== 0 && (
            <UserScreenshotsWidget
              screenshots={recentScreenshots}
              className="xl:row-span-2 lg:-order-8"
            />
          )}
          {unlockRequests.length !== 0 && (
            <UnlockRequestsWidget
              className={cx(
                `row-span-2 lg:-order-7`,
                hasNotifications && `2xl:row-span-3`,
              )}
              unlockRequests={unlockRequests}
            />
          )}
          <QuickActionsWidget date={date} className="xl:row-span-2 lg:-order-9" />
        </div>
      </>
    );
  }

  return (
    <UndoMainPadding className="flex justify-center items-center md:min-h-screen">
      <FloatingMessage className="flex flex-col items-center p-6 sm:p-8 lg:p-12">
        <h1 className="font-inter text-2xl xs:text-3xl lg:text-4xl text-center">
          Welcome to the parent website!
        </h1>
        <p className="text-base xs:text-lg sm:text-xl text-slate-600 text-center mt-4 max-w-xl">
          The first step to getting up and running is to
          {` `}
          <b>add a child</b>
          {` `}
          that you’d like to protect.
        </p>
        <div className="mt-12 flex flex-col gap-4">
          <OnboardingRecommendation
            title="Add a child"
            icon="fa-solid fa-user-plus"
            href="/children/new"
            primary
          />
          <div className="flex flex-col xl:flex-row gap-4">
            <OnboardingRecommendation
              title="How-to video (2 min)"
              icon="fa-brands fa-youtube"
              href="https://youtu.be/xMMuLngWhYE"
              openInNewTab
            />
            <OnboardingRecommendation
              title="Read our getting started guide"
              icon="fa-solid fa-question-circle"
              href="https://gertrude.app/docs/getting-started"
              openInNewTab
            />
          </div>
        </div>
      </FloatingMessage>
    </UndoMainPadding>
  );
};

export default Dashboard;

interface FloatingMessageProps {
  className?: string;
  children: React.ReactNode;
}

const FloatingMessage: React.FC<FloatingMessageProps> = ({ className, children }) => (
  <div className={`p-6 sm:p-8 xl:p-12 bg-fuchsia-radial-gradient`}>
    <div
      className={cx(
        `shadow-xl shadow-slate-300/50 rounded-3xl bg-white relative`,
        className,
      )}
    >
      {children}
    </div>
  </div>
);

interface OnboardingRecommendationProps {
  title: string;
  icon: string;
  href: string;
  primary?: boolean;
  openInNewTab?: boolean;
  className?: string;
}

export const OnboardingRecommendation: React.FC<OnboardingRecommendationProps> = ({
  title,
  icon,
  href,
  primary = false,
  openInNewTab = false,
  className,
}) => (
  <SmartLink
    to={href}
    className={cx(
      `flex items-center gap-4 p-2 pr-4 lg:pr-8 rounded-2xl border transition-[background-color] duration-150 group`,
      primary
        ? `border-violet-100 bg-violet-50/50 hover:bg-violet-50`
        : `border-slate-100 hover:bg-slate-50`,
      className,
    )}
    openInNewTab={openInNewTab}
  >
    <div
      className={cx(
        `w-12 h-12 rounded-xl flex justify-center items-center group-hover:-translate-y-1 transition-[box-shadow,transform] duration-200 group-hover:shadow-md shadow-none shrink-0`,
        primary
          ? `bg-gradient-to-br from-indigo-500 to-fuchsia-500 group-hover:shadow-black/20`
          : `bg-white border border-slate-100 group-hover:shadow-slate-300/50`,
      )}
    >
      <i
        className={cx(
          icon,
          primary
            ? `text-white text-lg`
            : `bg-gradient-to-br from-indigo-500 to-fuchsia-500 bg-clip-text [-webkit-background-clip:text;] text-xl text-transparent`,
        )}
      />
    </div>
    <span
      className={cx(
        `text-lg lg:text-xl font-bold leading-tight`,
        primary ? `text-slate-900` : `text-slate-700`,
      )}
    >
      {title}
    </span>
  </SmartLink>
);
