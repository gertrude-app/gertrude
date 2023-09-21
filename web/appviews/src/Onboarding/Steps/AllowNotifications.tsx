import React from 'react';
import type { AppEvent } from '../onboarding-store';
import { Button } from '@shared/components';
import ExpandableImage from '../ExpandableImage';
import GrantPermissionGif from '../images/grant-permission.gif';

interface Props {
  emit(event: AppEvent): unknown;
  os: 'catalina' | 'bigSurOrMonterey' | 'venturaOrLater';
  step: 'allowNotifications_start' | 'allowNotifications_grant';
}

const AllowNotifications: React.FC<Props> = ({ emit, step, os }) => {
  const systemSettings =
    os === `venturaOrLater` ? `System Settings` : `System Preferences`;
  switch (step) {
    case `allowNotifications_start`:
      return (
        <div className="h-full justify-center items-center flex flex-col">
          <h1 className="text-3xl font-bold">Now let's allow notifications</h1>
          <p className="mt-2 mb-8 text-lg text-slate-500 text-center max-w-xl">
            Gertrude sends <b>a small number of important notifications</b>, so it's
            important that your child sees them.
          </p>
          <img
            src="https://gertrude.nyc3.digitaloceanspaces.com/appview-assets/onboarding/notification.png"
            alt=""
            className="rounded-xl mb-8"
          />
          <div className="flex flex-row justify-center gap-4">
            <Button
              type="button"
              onClick={() => emit({ case: `primaryBtnClicked` })}
              color="primary"
              size="large"
            >
              Open {systemSettings}
              <i className="fa-solid fa-arrow-right ml-2" />
            </Button>
            <Button
              type="button"
              onClick={() => emit({ case: `secondaryBtnClicked` })}
              color="secondary"
              size="large"
            >
              Skip this step
            </Button>
          </div>
        </div>
      );
    case `allowNotifications_grant`:
      return (
        <div className="flex h-full items-center p-12 gap-12">
          <div className="flex flex-col">
            <h1 className="text-3xl font-bold">Set notifications to "Alerts"</h1>
            <p className="mt-4 text-lg text-slate-500 max-w-xl">
              We just opened the {systemSettings} app. Set Gertrude's notifications to
              {` `}
              <b>Alerts</b> as shown here:
            </p>
            <div className="flex flex-col gap-4 mt-8">
              <Button
                type="button"
                onClick={() => emit({ case: `primaryBtnClicked` })}
                color="primary"
                size="large"
              >
                Done
                <i className="fa-solid fa-arrow-right ml-2" />
              </Button>
              <Button
                type="button"
                onClick={() => emit({ case: `secondaryBtnClicked` })}
                color="secondary"
                size="large"
                className="shadow shadow-violet-200/80"
              >
                Help...
              </Button>
            </div>
          </div>
          <ExpandableImage
            src={GrantPermissionGif}
            alt={'Grant permission'}
            width={360}
            height={360 * 0.75}
          />
        </div>
      );
  }
};

export default AllowNotifications;
