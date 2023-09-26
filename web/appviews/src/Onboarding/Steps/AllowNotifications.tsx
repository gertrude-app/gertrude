import React from 'react';
import { Button } from '@shared/components';
import type { AppEvent } from '../onboarding-store';
import ExpandableImage from '../ExpandableImage';
import GrantPermissionGif from '../images/grant-permission.gif';

interface Props {
  emit(event: AppEvent): unknown;
  os: 'catalina' | 'bigSurOrMonterey' | 'venturaOrLater';
  step:
    | 'allowNotifications_start'
    | 'allowNotifications_grant'
    | 'allowNotifications_failed';
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
        <div className="flex h-full items-center justify-center p-12 gap-12">
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
            alt={`Grant permission`}
            width={360}
            height={360 * 0.75}
            showInstructions
          />
        </div>
      );
    case `allowNotifications_failed`:
      return (
        <div className="h-full flex flex-col justify-center items-center p-12">
          <h1 className="text-3xl font-bold">
            Shucks, the notifications still don't seem right
          </h1>
          <p className="mt-2 text-lg text-slate-500">
            Watch the video for more information.
          </p>
          <iframe
            className="my-6 rounded-xl"
            width="560"
            height="315"
            src="https://www.youtube-nocookie.com/embed/ytN1HhQX3xo?rel=0"
            title="YouTube video player"
            allowFullScreen
          />
          <div className="flex flex-col w-80 gap-4">
            <Button
              color="primary"
              size="large"
              type="button"
              onClick={() => emit({ case: `primaryBtnClicked` })}
              className="shadow shadow-violet-200/80"
            >
              Check again
              <i className="fa-solid fa-arrow-right ml-2" />
            </Button>
            <Button
              color="secondary"
              size="large"
              type="button"
              onClick={() => emit({ case: `primaryBtnClicked` })}
              className="shadow shadow-violet-200/80"
            >
              Skip for now
            </Button>
          </div>
        </div>
      );
  }
};

export default AllowNotifications;
