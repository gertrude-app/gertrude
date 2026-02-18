import { posessive } from '@shared/string';
import cx from 'classnames';
import React, { useState } from 'react';
import type {
  DashboardWidgets_v2,
  MacAppConnectionCode,
  RequestState,
} from '@dash/types';
import { UndoMainPadding } from '../Chrome/Chrome';
import PageHeading from '../PageHeading';
import SmartLink from '../SmartLink';
import AddDeviceInstructions from '../Users/AddDeviceInstructions';
import ConnectDeviceModal from '../Users/ConnectDeviceModal';
import AttentionBanner from './AttentionBanner';
import ChildrenDevicesWidget from './ChildrenDevicesWidget';
import CreateFirstNotificationWidget from './CreateFirstNotificationWidget';
import QuickActionsWidget from './QuickActionsWidget';
import UnlockRequestsWidget from './UnlockRequestsWidget';
import UserActivityWidget from './UserActivityWidget';
import UserScreenshotsWidget from './UserScreenshotsWidget';
import UserOverviewWidget from './UsersOverviewWidget';

type Props = {
  date?: Date;
  startAddDevice(childId: UUID): unknown;
  dismissAddDevice(): unknown;
  dismissAnnouncement(id: UUID): unknown;
  onStartTrial(): unknown;
  addDeviceRequest: RequestState<MacAppConnectionCode.Output>;
  childData: DashboardWidgets_v2.Output[`children`];
  pendingIosDevices?: DashboardWidgets_v2.Output[`pendingIOSDevices`];
} & Omit<DashboardWidgets_v2.Output, `children` | `pendingIOSDevices`>;

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
  const hasMacDevices = childData.some((c) => c.devices.some((d) => d.macStatus));
  const firstUser = childData[0];
  if (firstUser && childData.reduce((acc, cur) => acc + cur.devices.length, 0) === 0) {
    return (
      <ConnectFirstDeviceScreen
        firstUser={firstUser}
        startAddDevice={startAddDevice}
        dismissAddDevice={dismissAddDevice}
        onStartTrial={onStartTrial}
        addDeviceRequest={addDeviceRequest}
      />
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
          {hasMacDevices && !hasNotifications && (
            <CreateFirstNotificationWidget className="@3xl:-order-10" />
          )}
          {hasMacDevices && <UserActivityWidget userActivity={childActivitySummaries} />}
          <ChildrenDevicesWidget children={childData} />
          <UserOverviewWidget users={childData} />
          {hasMacDevices && recentScreenshots.length !== 0 && (
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
          <QuickActionsWidget
            date={date}
            hasMacDevices={hasMacDevices}
            className="@3xl:-order-10 @6xl:row-span-2"
          />
        </div>
      </div>
    );
  }

  return <WelcomeScreen />;
};

export default Dashboard;

type Platform = `mac` | `ios`;

const WelcomeScreen: React.FC = () => {
  const [platform, setPlatform] = useState<Platform | undefined>();
  return (
    <UndoMainPadding className="flex justify-center items-center md:min-h-screen">
      <FloatingMessage className="flex flex-col items-center p-6 sm:p-8 lg:p-12 max-w-3xl">
        {!platform ? (
          <>
            <h1 className="font-inter text-2xl xs:text-3xl lg:text-4xl text-center">
              Welcome to Gertrude!
            </h1>
            <p className="text-base xs:text-lg sm:text-xl text-slate-600 text-center mt-4 max-w-xl">
              What type of device would you like to protect?
            </p>
            <div className="mt-12 flex flex-col sm:flex-row gap-4 w-full max-w-lg">
              <PlatformOption
                icon="fa-solid fa-laptop"
                title="Mac computer"
                onClick={() => setPlatform(`mac`)}
              />
              <PlatformOption
                icon="fa-solid fa-mobile-screen"
                title="iPhone or iPad"
                onClick={() => setPlatform(`ios`)}
              />
            </div>
          </>
        ) : platform === `mac` ? (
          <>
            <button
              onClick={() => setPlatform(undefined)}
              className="self-start -mt-4 -ml-4 mb-2 text-slate-400 hover:text-slate-600 transition-colors text-sm"
            >
              <i className="fa-solid fa-arrow-left mr-1.5" />
              Back
            </button>
            <h1 className="font-inter text-2xl xs:text-3xl lg:text-4xl text-center">
              Protect a Mac
            </h1>
            <p className="text-base xs:text-lg sm:text-xl text-slate-600 text-center mt-4 max-w-xl">
              The first step is to <b>add a child</b> that you'd like to protect.
            </p>
            <div className="mt-12 flex flex-col gap-4">
              <OnboardingRecommendation
                title="Add a child"
                icon="fa-solid fa-user-plus"
                href="/children/new"
                primary
              />
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
          </>
        ) : (
          <>
            <button
              onClick={() => setPlatform(undefined)}
              className="self-start -mt-4 -ml-4 mb-2 text-slate-400 hover:text-slate-600 transition-colors text-sm"
            >
              <i className="fa-solid fa-arrow-left mr-1.5" />
              Back
            </button>
            <IosGetStartedInstructions />
          </>
        )}
      </FloatingMessage>
    </UndoMainPadding>
  );
};

interface ConnectFirstDeviceScreenProps {
  firstUser: DashboardWidgets_v2.Output[`children`][number];
  startAddDevice(childId: UUID): unknown;
  dismissAddDevice(): unknown;
  onStartTrial(): unknown;
  addDeviceRequest: RequestState<MacAppConnectionCode.Output>;
}

const ConnectFirstDeviceScreen: React.FC<ConnectFirstDeviceScreenProps> = ({
  firstUser,
  startAddDevice,
  dismissAddDevice,
  onStartTrial,
  addDeviceRequest,
}) => {
  const [platform, setPlatform] = useState<Platform | undefined>();
  return (
    <>
      <ConnectDeviceModal
        request={addDeviceRequest}
        dismissAddDevice={dismissAddDevice}
        onStartTrial={onStartTrial}
      />
      <UndoMainPadding className="flex justify-center items-center md:min-h-screen">
        <FloatingMessage className="flex flex-col items-center p-6 sm:p-8 lg:p-12 max-w-3xl">
          {!platform ? (
            <>
              <h1 className="font-inter text-xl xs:text-2xl lg:text-3xl text-center">
                What type of device will {firstUser.name} be using?
              </h1>
              <div className="mt-12 flex flex-col sm:flex-row gap-4 w-full max-w-lg">
                <PlatformOption
                  icon="fa-solid fa-laptop"
                  title="Mac computer"
                  onClick={() => setPlatform(`mac`)}
                />
                <PlatformOption
                  icon="fa-solid fa-mobile-screen"
                  title="iPhone or iPad"
                  onClick={() => setPlatform(`ios`)}
                />
              </div>
            </>
          ) : platform === `mac` ? (
            <>
              <button
                onClick={() => setPlatform(undefined)}
                className="self-start -mt-4 -ml-4 mb-2 text-slate-400 hover:text-slate-600 transition-colors text-sm"
              >
                <i className="fa-solid fa-arrow-left mr-1.5" />
                Back
              </button>
              <AddDeviceInstructions
                userName={firstUser.name}
                userId={firstUser.id}
                startAddDevice={startAddDevice}
              />
            </>
          ) : (
            <>
              <button
                onClick={() => setPlatform(undefined)}
                className="self-start -mt-4 -ml-4 mb-2 text-slate-400 hover:text-slate-600 transition-colors text-sm"
              >
                <i className="fa-solid fa-arrow-left mr-1.5" />
                Back
              </button>
              <IosGetStartedInstructions childName={firstUser.name} />
            </>
          )}
        </FloatingMessage>
      </UndoMainPadding>
    </>
  );
};

const IosGetStartedInstructions: React.FC<{ childName?: string }> = ({ childName }) => (
  <>
    <h1 className="font-inter text-2xl xs:text-3xl lg:text-4xl text-center">
      Protect {childName ? `${posessive(childName)} iPhone or iPad` : `an iPhone or iPad`}
    </h1>
    <p className="text-base xs:text-lg sm:text-xl text-slate-600 text-center mt-4 max-w-xl">
      {childName ? `Search` : `To get started, search`} for <b>Gertrude Blocker</b> in the
      App Store on{` `}
      {childName ? `${posessive(childName)} device` : `your child's iPhone or iPad`}. The
      app will walk you through the setup process.
    </p>
    <div className="mt-12 flex flex-col gap-4">
      <OnboardingRecommendation
        title="Download from the App Store"
        icon="fa-brands fa-app-store-ios"
        href="https://apps.apple.com/app/gertrude/id6740543928"
        openInNewTab
        primary
      />
    </div>
  </>
);

interface PlatformOptionProps {
  icon: string;
  title: string;
  onClick(): void;
}

const PlatformOption: React.FC<PlatformOptionProps> = ({ icon, title, onClick }) => (
  <button
    onClick={onClick}
    className="flex-1 flex flex-col items-center gap-4 p-6 sm:p-8 rounded-2xl border border-slate-200 hover:border-violet-200 hover:bg-violet-50/50 transition-all duration-200 group"
  >
    <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-indigo-500 to-fuchsia-500 flex justify-center items-center group-hover:-translate-y-1 transition-[box-shadow,transform] duration-200 group-hover:shadow-md group-hover:shadow-black/20">
      <i className={cx(icon, `text-white text-2xl`)} />
    </div>
    <span className="text-lg font-bold text-slate-800">{title}</span>
  </button>
);

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
