import { posessive } from '@shared/string';
import cx from 'classnames';
import React, { useState } from 'react';
import type {
  CreatePendingAppConnection_v2,
  DashboardWidgets,
  RequestState,
} from '@dash/types';
import { UndoMainPadding } from '../Chrome/Chrome';
import PageHeading from '../PageHeading';
import SmartLink from '../SmartLink';
import AddDeviceInstructions from '../Users/AddDeviceInstructions';
import ConnectDeviceModal from '../Users/ConnectDeviceModal';
import AttentionBanner from './AttentionBanner';
import CreateFirstNotificationWidget from './CreateFirstNotificationWidget';
import QuickActionsWidget from './QuickActionsWidget';
import UnlockRequestsWidget from './UnlockRequestsWidget';
import UserActivityWidget from './UserActivityWidget';
import UserScreenshotsWidget from './UserScreenshotsWidget';
import UserOverviewWidget from './UsersOverviewWidget';

export type PendingIosDevice = {
  childName: string;
  modelName: string;
  claimCode: number;
};

type Props = {
  date?: Date;
  startAddDevice(childId: UUID): unknown;
  dismissAddDevice(): unknown;
  dismissAnnouncement(id: UUID): unknown;
  onStartTrial(): unknown;
  addDeviceRequest: RequestState<CreatePendingAppConnection_v2.Output>;
  childData: DashboardWidgets.Output[`children`];
  pendingIosDevices?: PendingIosDevice[];
} & Omit<DashboardWidgets.Output, `children` | `pendingIOSDevices`>;

const Dashboard: React.FC<Props> = ({
  unlockRequests,
  childData,
  childActivitySummaries,
  recentScreenshots,
  date = new Date(),
  startAddDevice,
  dismissAddDevice,
  dismissAnnouncement,
  onStartTrial,
  addDeviceRequest,
  numParentNotifications,
  announcement,
  pendingIosDevices = [],
}) => {
  const [announcementDismissed, setAnnouncementDismissed] = useState(false);
  const hasNotifications = numParentNotifications > 0;
  const firstUser = childData[0];
  if (firstUser && childData.reduce((acc, cur) => acc + cur.numDevices, 0) === 0) {
    return (
      <>
        <ConnectDeviceModal
          request={addDeviceRequest}
          dismissAddDevice={dismissAddDevice}
          onStartTrial={onStartTrial}
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

  if (childData.length > 0) {
    return (
      <div className="@container">
        <PageHeading icon="home">Dashboard</PageHeading>
        {pendingIosDevices.map((device) => (
          <AttentionBanner
            key={device.claimCode}
            icon="fa-solid fa-mobile-screen"
            heading={`${posessive(device.childName)} ${device.modelName} is almost ready`}
            subtext="Download the supervision tool to finish setting up."
            linkTo={`/supervise-device/${device.claimCode}/download-helper`}
            linkText="Continue Setup"
            className="mt-5"
          />
        ))}
        {announcement && !announcementDismissed && (
          <AttentionBanner
            kind={announcement.kind}
            icon={announcement.icon ?? `fa fa-bolt`}
            html={announcement.html}
            learnMoreUrl={announcement.learnMoreUrl}
            onDismiss={() => {
              dismissAnnouncement(announcement.id);
              setAnnouncementDismissed(true);
            }}
            className="mt-5"
          />
        )}
        <div className="pt-6 grid grid-cols-1 @3xl:grid-cols-2 @6xl:grid-cols-3 gap-4 @3xl:gap-6 @6xl:gap-8">
          {!hasNotifications && (
            <CreateFirstNotificationWidget className="@3xl:-order-10" />
          )}
          <UserActivityWidget userActivity={childActivitySummaries} />
          <UserOverviewWidget
            users={childData}
            className={cx(!hasNotifications && `@3xl:col-span-2 @6xl:col-span-1`)}
          />
          {recentScreenshots.length !== 0 && (
            <UserScreenshotsWidget
              screenshots={recentScreenshots}
              className="@3xl:-order-9 @6xl:row-span-2"
            />
          )}
          {unlockRequests.length !== 0 && (
            <UnlockRequestsWidget
              className={cx(
                `row-span-2 @3xl:-order-8`,
                hasNotifications && `@6xl:row-span-3`,
              )}
              unlockRequests={unlockRequests}
            />
          )}
          <QuickActionsWidget date={date} className="@3xl:-order-10 @6xl:row-span-2" />
        </div>
      </div>
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
