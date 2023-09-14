import React from 'react';
import type { AppEvent } from '../onboarding-store';

interface Props {
  emit(event: AppEvent): unknown;
  os: 'catalina' | 'bigSurOrMonterey' | 'venturaOrLater';
  step:
    | 'installSysExt_explain'
    | 'installSysExt_start'
    | 'installSysExt_allowInstall'
    | 'installSysExt_allowFiltering'
    | 'installSysExt_failed'
    | 'installSysExt_success';
}

const InstallSysExt: React.FC<Props> = ({ emit, step, os }) => (
  <div>
    <h1 className="text-3xl mb-3">Install System Extension</h1>
    <AllowKeyloggingStep emit={emit} step={step} os={os} />
  </div>
);

const AllowKeyloggingStep: React.FC<Props> = ({ emit, step, os }) => {
  const systemSettings =
    os === `venturaOrLater` ? `System Settings` : `System Preferences`;
  switch (step) {
    case `installSysExt_explain`:
      return (
        <>
          <p className="my-4">
            What gives Gertrude it's superpowers is something called a{` `}
            <b>system extension</b>. Because it's so powerful, you have to give it special
            permission to do it's job.
          </p>
          <div className="my-4 bg-blue-100 px-4 py-2 rounded-lg">
            <b>Good to know:</b>
            <ul className="list-disc list-inside">
              <li>You can disable and remove the system extension at any time</li>
            </ul>
          </div>
          <button
            className="bg-blue-500 text-white font-bold py-2 px-4"
            onClick={() => emit({ case: `primaryBtnClicked` })}
          >
            Next &rarr;
          </button>
        </>
      );
    case `installSysExt_start`:
      return (
        <>
          <p className="my-4">
            When you click the button below, then be sure to choose the <b>GRAY</b> button
            to open {systemSettings}.
          </p>
          <img
            className="h-[380px] rounded-lg mb-4"
            src="https://gertrude.nyc3.digitaloceanspaces.com/appview-assets/onboarding/dont-block-install-sys-ext.png"
            alt=""
          />
          <button
            className="bg-blue-500 text-white font-bold py-2 px-4"
            onClick={() => emit({ case: `primaryBtnClicked` })}
          >
            Start the installation &rarr;
          </button>
        </>
      );
    case `installSysExt_allowInstall`:
      return (
        <>
          <ol className="my-4">
            Next, in the {systemSettings} app follow the steps shown below to allow the
            installation:
          </ol>
          <img
            className="h-[280px] rounded-lg mb-4"
            src="https://gertrude.nyc3.digitaloceanspaces.com/appview-assets/onboarding/allow-sys-ext.png"
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
            Help, I'm stuck...
          </button>
        </>
      );
    case `installSysExt_failed`:
      return (
        <>
          <p>
            Shucks! The system extension did not install correctly. Watch this short video
            for troubleshooting tips.
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
            Try again &rarr;
          </button>
          <button
            className="bg-gray-400 text-white font-bold py-2 px-4"
            onClick={() => emit({ case: `secondaryBtnClicked` })}
          >
            Skip install for now...
          </button>
        </>
      );
    case `installSysExt_success`:
      return (
        <>
          <p>
            🎉 Hooray, we've confirmed the system extension is <em>ready to go!</em>
          </p>
          <div className="my-4 bg-blue-100 p-5 rounded-lg">
            <b>Good to know:</b>
            <p>
              You're past all the hard parts, all that's left it to briefly show you
              around a bit.
            </p>
          </div>
          <button
            className="bg-blue-500 text-white font-bold py-2 px-4"
            onClick={() => emit({ case: `primaryBtnClicked` })}
          >
            Next &rarr;
          </button>
        </>
      );
    default:
      return <h1>{step}</h1>;
  }
};

export default InstallSysExt;
