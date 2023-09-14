import React from 'react';
import type { AppEvent } from '../onboarding-store';

interface Props {
  emit(event: AppEvent): unknown;
  os: 'catalina' | 'bigSurOrMonterey' | 'venturaOrLater';
  step: 'allowNotifications_start' | 'allowNotifications_grant';
}

const AllowNotifications: React.FC<Props> = ({ emit, step, os }) => (
  <div>
    <h1 className="text-3xl mb-3">Allow Notifications</h1>
    <AllowNotificationsStep emit={emit} step={step} os={os} />
  </div>
);

const AllowNotificationsStep: React.FC<Props> = ({ emit, step, os }) => {
  const systemSettings =
    os === `venturaOrLater` ? `System Settings` : `System Preferences`;
  switch (step) {
    case `allowNotifications_start`:
      return (
        <>
          <p className="mb-3">
            Gertrude sends <b>a small number of important notifications</b>, so it's
            important that your child sees them.
          </p>

          <img
            src="https://gertrude.nyc3.digitaloceanspaces.com/appview-assets/onboarding/notification.png"
            alt=""
            className="rounded-xl mb-4"
          />
          <button
            className="bg-blue-500 text-white font-bold py-2 px-4"
            onClick={() => emit({ case: `primaryBtnClicked` })}
          >
            Open {systemSettings} &rarr;
          </button>
          <button
            className="bg-gray-400 text-white font-bold py-2 px-4"
            onClick={() => emit({ case: `primaryBtnClicked` })}
          >
            Skip this step...
          </button>
        </>
      );
    case `allowNotifications_grant`:
      return (
        <>
          <p>
            We just opened the {systemSettings} app. Set Gertrude's notifications to{` `}
            <b>Alerts</b> as shown here:
          </p>
          <img
            src="https://gertrude.nyc3.digitaloceanspaces.com/appview-assets/onboarding/notification-alerts.png"
            alt="Grant permission"
            className="h-[400px] rounded-xl"
          />
          <button
            className="bg-blue-500 text-white font-bold py-2 px-4"
            onClick={() => emit({ case: `primaryBtnClicked` })}
          >
            Done &rarr;
          </button>
          <button
            className="bg-gray-400 text-white font-bold py-2 px-4"
            onClick={() => emit({ case: `primaryBtnClicked` })}
          >
            Help...
          </button>
        </>
      );
  }
};

export default AllowNotifications;
