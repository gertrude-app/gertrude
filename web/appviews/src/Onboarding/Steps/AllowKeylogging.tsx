import React from 'react';
import { Button } from '@shared/components';
import type { AppEvent } from '../onboarding-store';
import Callout from '../Callout';
import ExpandableImage from '../ExpandableImage';

interface Props {
  emit(event: AppEvent): unknown;
  os: 'catalina' | 'bigSurOrMonterey' | 'venturaOrLater';
  step:
    | 'allowKeylogging_required'
    | 'allowKeylogging_openSysSettings'
    | 'allowKeylogging_grant'
    | 'allowKeylogging_failed';
}

const AllowKeylogging: React.FC<Props> = ({ emit, step, os }) => {
  const systemSettings =
    os === `venturaOrLater` ? `System Settings` : `System Preferences`;
  switch (step) {
    case `allowKeylogging_required`:
      return (
        <div className="h-full flex flex-col justify-center items-center">
          <h1 className="text-3xl font-bold">Now let's allow keylogging</h1>
          <p className="mt-4 mb-8 text-lg text-slate-500 max-w-2xl text-center">
            Gertrude needs your permission to record what your child types
          </p>
          <Callout heading="Good to know:" type="info">
            <ul className="list-disc list-inside ml-2">
              <li>You control if and when we record typing</li>
              <li>Your child is shown their typing is being recorded</li>
              <li>
                We can't record passwords, credit card numbers, or other sensitive info
              </li>
            </ul>
          </Callout>
          <div className="flex flex-col w-80 gap-4 mt-8">
            <Button
              color="primary"
              size="large"
              type="button"
              onClick={() => emit({ case: `primaryBtnClicked` })}
              className="shadow shadow-violet-200/80"
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
    case `allowKeylogging_openSysSettings`:
      return (
        <div className="h-full flex items-center justify-center p-12 gap-12">
          <div className="flex flex-col">
            <h1 className="text-3xl font-bold">Open {systemSettings}</h1>
            <p className="text-lg text-slate-500 max-w-lg mt-4">
              Just now, a system popup should have appeared that looks like this. Find it
              and click{` `}
              <b>Open {systemSettings}.</b>
            </p>
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
          <ExpandableImage
            src="https://gertrude.nyc3.digitaloceanspaces.com/appview-assets/onboarding/venturaOrLater/accessibility-access.png"
            alt={`Grant permission`}
            width={640 / 2}
            height={490 / 2}
          />
        </div>
      );
    case `allowKeylogging_grant`:
      return (
        <div className="flex flex-col h-full justify-center items-center">
          <h1 className="text-3xl font-bold">Allow keylogging</h1>
          <p className="text-lg text-slate-500 max-w-xl text-center mt-4 mb-8">
            Now, in the {systemSettings} app, follow the steps shown below.
          </p>
          <ExpandableImage
            src="https://gertrude.nyc3.digitaloceanspaces.com/appview-assets/onboarding/screen-recording-add-gertrude.gif"
            alt={`Grant permission`}
            width={900 / 2}
            height={650 / 2}
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
              Help, I'm having trouble...
            </Button>
          </div>
        </div>
      );
    case `allowKeylogging_failed`:
      return (
        <div className="h-full flex justify-center items-center flex-col">
          <h1 className="text-3xl font-bold mb-2">Hmm, somthing didn't work...</h1>
          <p className="text-lg text-slate-500 text-center max-w-2xl">
            Shucks! We still don't seem to have the permission we need. Watch the short
            video below for troubleshooting steps:
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
              Done, recheck
              <i className="fa-solid fa-arrow-right ml-2" />
            </Button>
            <Button
              color="secondary"
              size="large"
              type="button"
              onClick={() => emit({ case: `primaryBtnClicked` })}
              className="shadow shadow-violet-200/80"
            >
              Skip this for now...
            </Button>
          </div>
        </div>
      );
  }
};

export default AllowKeylogging;
