import React from 'react';
import type { AppEvent } from '../onboarding-store';
import GrantPermission from '../images/grant-permission.png';

interface Props {
  emit(event: AppEvent): unknown;
  os: 'catalina' | 'bigSurOrMonterey' | 'venturaOrLater';
  step:
    | 'allowKeylogging_required'
    | 'allowKeylogging_openSysSettings'
    | 'allowKeylogging_grant'
    | 'allowKeylogging_failed'
    | 'allowKeylogging_success';
}

const AllowKeylogging: React.FC<Props> = ({ emit, step, os }) => (
  <div>
    <h1 className="text-3xl mb-3">Allow Recording Typing</h1>
    <AllowKeyloggingStep emit={emit} step={step} os={os} />
  </div>
);

const AllowKeyloggingStep: React.FC<Props> = ({ emit, step, os }) => {
  const systemSettings =
    os === `venturaOrLater` ? `System Settings` : `System Preferences`;
  switch (step) {
    case `allowKeylogging_required`:
      return (
        <>
          <p className="mb-3">
            Gertrude needs your permission to record what your child types.
          </p>
          <div className="my-4 bg-blue-100 px-4 py-2 rounded-lg">
            <b>Good to know:</b>
            <ul className="list-disc list-inside">
              <li>You control if and when we record typing</li>
              <li>Your child is shown when their typing is being recorded</li>
              <li>
                We can't record passwords, credit card numbers, or other sensitive info
              </li>
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
    case `allowKeylogging_openSysSettings`:
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
    case `allowKeylogging_grant`:
      return (
        <>
          <p>Next, in the {systemSettings} app, follow the steps shown below:</p>
          <img
            src="https://gertrude.nyc3.digitaloceanspaces.com/appview-assets/onboarding/screen-recording-add-gertrude.gif"
            className="h-[425px] rounded-xl"
            alt=""
          />
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
            Help, I'm having trouble...
          </button>
        </>
      );
    case `allowKeylogging_failed`:
      return (
        <>
          <p>
            Shucks! We still don't seem to have the permission we need. Watch the short
            video below for troubleshooting steps:
          </p>
          <iframe
            className="my-4"
            width="560"
            height="315"
            src="https://www.youtube-nocookie.com/embed/ytN1HhQX3xo?rel=0"
            title="YouTube video player"
            frameBorder="0"
            allowFullScreen
          />
          <button
            className="bg-blue-500 text-white font-bold py-2 px-4"
            onClick={() => emit({ case: `primaryBtnClicked` })}
          >
            Done, recheck &rarr;
          </button>
          <button
            className="bg-gray-400 text-white font-bold py-2 px-4"
            onClick={() => emit({ case: `secondaryBtnClicked` })}
          >
            Skip this for now...
          </button>
        </>
      );
    case `allowKeylogging_success`:
      return (
        <>
          <p>🎉 Hooray, Gertrude has the permission it needs to record typing.</p>
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

export default AllowKeylogging;
