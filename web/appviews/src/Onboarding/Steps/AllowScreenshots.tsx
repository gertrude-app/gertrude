import React from 'react';
import { Button } from '@shared/components';
import type { AppEvent } from '../onboarding-store';
import GrantPermission from '../images/grant-permission.png';
import Callout from '../Callout';
import ExpandableImage from '../ExpandableImage';

interface Props {
  emit(event: AppEvent): unknown;
  os: 'catalina' | 'bigSurOrMonterey' | 'venturaOrLater';
  step:
    | 'allowScreenshots_required'
    | 'allowScreenshots_openSysSettings'
    | 'allowScreenshots_grantAndRestart'
    | 'allowScreenshots_failed'
    | 'allowScreenshots_success';
}

const AllowScreenshots: React.FC<Props> = ({ emit, step, os }) => {
  const systemSettings =
    os === `venturaOrLater` ? `System Settings` : `System Preferences`;
  switch (step) {
    case `allowScreenshots_required`:
      return (
        <div className="flex flex-col items-center justify-center h-full">
          <h1 className="text-3xl font-bold">Grant screen recording permission</h1>
          <p className="mt-4 mb-8 text-lg text-slate-500 max-w-2xl text-center">
            Gertrude needs your permission to record the screen, so it can take
            screenshots of your child's activity.
          </p>
          <Callout heading="Good to know:" type="info">
            <ul className="list-disc list-inside ml-2">
              <li>You control if and when we record screenshots</li>
              <li>Your child is shown when their screen is being recorded</li>
            </ul>
          </Callout>
          <div className="flex flex-col w-80 gap-4 mt-8">
            <Button
              color="primary"
              size="large"
              type="button"
              onClick={() => emit({ case: `primaryBtnClicked` })}
            >
              Grant permission
              <i className="fa-solid fa-arrow-right ml-2" />
            </Button>
            <Button
              color="secondary"
              size="large"
              type="button"
              onClick={() => emit({ case: `primaryBtnClicked` })}
              className="shadow shadow-violet-200/80"
            >
              Skip this step...
            </Button>
          </div>
        </div>
      );
    case `allowScreenshots_openSysSettings`:
      return (
        <div className="h-full flex flex-col items-center justify-center">
          <h1 className="text-3xl font-bold">Open {systemSettings}</h1>
          <p className="text-lg text-slate-500 max-w-xl text-center mt-4 mb-8">
            Just now, a system popup should have appeared that looks like this. Find it
            and click{` `}
            <b>Open {systemSettings}.</b>
          </p>
          <ExpandableImage
            src={GrantPermission}
            alt={`Grant permission`}
            width={450}
            height={200}
          />
          <div className="flex flex-col w-80 gap-4 mt-8">
            <Button
              color="primary"
              size="large"
              type="button"
              onClick={() => emit({ case: `primaryBtnClicked` })}
              className="shadow shadow-violet-200/80"
            >
              Done
              <i className="fa-solid fa-arrow-right ml-2" />
            </Button>
            <Button
              color="secondary"
              size="large"
              type="button"
              onClick={() => emit({ case: `primaryBtnClicked` })}
              className="shadow shadow-violet-200/80"
            >
              Can't find the popup...
            </Button>
          </div>
        </div>
      );
    case `allowScreenshots_grantAndRestart`:
      return (
        <div className="h-full flex flex-col justify-center items-center">
          <h1 className="text-3xl font-bold">Allow screenshots</h1>
          <p className="text-lg text-slate-500 max-w-2xl text-center mt-4 mb-8">
            Follow the steps shown below, which include <b>quitting Gertrude.</b> This
            screen will open again when it restarts.
          </p>
          <ExpandableImage
            src="https://gertrude.nyc3.digitaloceanspaces.com/appview-assets/onboarding/screen-recording-add-gertrude.gif"
            alt={`Allow screenshots`}
            width={900 / 2}
            height={650 / 2}
          />
          <Button
            color="tertiary"
            size="large"
            type="button"
            onClick={() => emit({ case: `primaryBtnClicked` })}
            className="mt-8"
          >
            Help, I'm still here...
          </Button>
        </div>
      );
    case `allowScreenshots_success`:
      return (
        <div className="h-full flex flex-col justify-center items-center">
          <div className="flex flex-col items-center bg-white p-12 rounded-3xl shadow-lg shadow-slate-300/30">
            <h1 className="text-3xl font-bold">Awesome!</h1>
            <p className="text-lg text-slate-500 max-w-xl text-center mt-4">
              Gertrude now has the permission it needs to take screenshots.
            </p>
            <Button
              color="primary"
              size="large"
              type="button"
              onClick={() => emit({ case: `primaryBtnClicked` })}
              className="mt-8"
            >
              Next
              <i className="fa-solid fa-arrow-right ml-2" />
            </Button>
          </div>
        </div>
      );
    case `allowScreenshots_failed`:
      return (
        <div className="h-full flex flex-col justify-center items-center p-12">
          <div className="flex flex-col items-center border-2 border-slate-200/60 border-dashed p-12 rounded-3xl">
            <h1 className="text-3xl font-bold">Hmm... something didn't work</h1>
            <p className="text-lg text-slate-500 mt-4">
              We still don't have permission to record the screen. Please try again.
            </p>
            <div className="flex flex-col w-80 gap-4 mt-8">
              <Button
                color="primary"
                size="large"
                type="button"
                onClick={() => emit({ case: `primaryBtnClicked` })}
                className="shadow shadow-violet-200/80"
              >
                Try again
                <i className="fa-solid fa-arrow-right ml-2" />
              </Button>
              <Button
                color="secondary"
                size="large"
                type="button"
                onClick={() => emit({ case: `primaryBtnClicked` })}
                className="shadow shadow-violet-200/80"
              >
                Skip this step...
              </Button>
            </div>
          </div>
        </div>
      );
  }
};

export default AllowScreenshots;
