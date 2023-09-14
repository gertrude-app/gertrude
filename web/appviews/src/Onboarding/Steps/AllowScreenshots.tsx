import React from 'react';
import type { AppEvent } from '../onboarding-store';
import GrantPermission from '../images/grant-permission.png';

interface Props {
  emit(event: AppEvent): unknown;
  os: 'catalina' | 'bigSurOrMonterey' | 'venturaOrLater';
  step:
    | 'allowScreenshots_required'
    | 'allowScreenshots_openSysSettings'
    | 'allowScreenshots_grantAndRestart'
    | 'allowScreenshots_success';
}

const AllowScreenshots: React.FC<Props> = ({ emit, step, os }) => (
  <div>
    <h1 className="text-3xl mb-3">Allow Screen Recording</h1>
    <AllowScreenshotsStep emit={emit} step={step} os={os} />
  </div>
);

const AllowScreenshotsStep: React.FC<Props> = ({ emit, step, os }) => {
  const systemSettings =
    os === `venturaOrLater` ? `System Settings` : `System Preferences`;
  switch (step) {
    case `allowScreenshots_required`:
      return (
        <>
          <p className="mb-3">
            Gertrude needs your permission to record the screen, so it can take
            screenshots of your child's activity.
          </p>

          <div className="my-4 bg-blue-100 px-4 py-2 rounded-lg">
            <b>Good to know:</b>
            <ul className="list-disc list-inside">
              <li>You control if and when we record screenshots</li>
              <li>Your child is shown when their screen is being recorded</li>
            </ul>
          </div>
          <button
            className="bg-blue-500 text-white font-bold py-2 px-4"
            onClick={() => emit({ case: `primaryBtnClicked` })}
          >
            Grant permission &rarr;
          </button>
          <button
            className="bg-gray-400 text-white font-bold py-2 px-4"
            onClick={() => emit({ case: `secondaryBtnClicked` })}
          >
            Skip this step...
          </button>
        </>
      );
    case `allowScreenshots_openSysSettings`:
      return (
        <>
          <p>
            Just now, a system popup should have appeared that looks like this:
            <img src={GrantPermission} alt="Grant permission" className="rounded-xl" />
            Find it and click{` `}
            <b>Open {systemSettings}.</b>
          </p>
          <button
            className="bg-blue-500 text-white font-bold py-2 px-4"
            onClick={() => emit({ case: `primaryBtnClicked` })}
          >
            Done &rarr;
          </button>
          <button
            className="bg-gray-400 text-white font-bold py-2 px-4"
            onClick={() => emit({ case: `secondaryBtnClicked` })}
          >
            Can't find the popup...
          </button>
        </>
      );
    case `allowScreenshots_grantAndRestart`:
      return (
        <>
          <p>
            Follow the steps shown below, which include <b>quitting Gertrude.</b> This
            screen will open again when it restarts.
          </p>
          <img
            src="https://gertrude.nyc3.digitaloceanspaces.com/appview-assets/onboarding/screen-recording-add-gertrude.gif"
            className="h-[425px] rounded-xl"
            alt=""
          />
          <button
            className="bg-gray-400 text-white font-bold py-2 px-4"
            onClick={() => emit({ case: `secondaryBtnClicked` })}
          >
            Help, I'm still here...
          </button>
        </>
      );
    case `allowScreenshots_success`:
      return (
        <>
          <p>🎉 Hooray, Gertrude has the permission it needs to take screenshots.</p>
          <button
            className="bg-blue-500 text-white font-bold py-2 px-4"
            onClick={() => emit({ case: `primaryBtnClicked` })}
          >
            Next &rarr;
          </button>
        </>
      );
  }
};

export default AllowScreenshots;
