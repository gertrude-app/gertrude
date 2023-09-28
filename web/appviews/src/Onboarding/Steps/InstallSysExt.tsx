import React from 'react';
import { Button } from '@shared/components';
import type { AppEvent, OSGroup } from '../onboarding-store';
import Callout from '../Callout';
import ExpandableImage from '../ExpandableImage';

interface Props {
  emit(event: AppEvent): unknown;
  os: OSGroup;
  step:
    | 'installSysExt_explain'
    | 'installSysExt_start'
    | 'installSysExt_allowInstall'
    | 'installSysExt_allowFiltering'
    | 'installSysExt_failed'
    | 'installSysExt_success';
}

const InstallSysExt: React.FC<Props> = ({ emit, step, os }) => {
  const systemSettings =
    os === `venturaOrLater` ? `System Settings` : `System Preferences`;
  switch (step) {
    case `installSysExt_explain`:
      return (
        <div className="h-full flex flex-col justify-center items-center p-12">
          <h1 className="text-3xl font-bold">Just one more step!</h1>
          <p className="my-4 max-w-2xl text-lg text-center text-slate-500 mb-8">
            What gives Gertrude it's superpowers is something called a{` `}
            <b>system extension</b>. Because it's so powerful, you have to give it special
            permission to do it's job.
          </p>
          <Callout heading="Good to know:" type="info">
            <p>You can disable and remove the system extension at any time.</p>
          </Callout>
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
      );
    case `installSysExt_start`:
      return (
        <div className="h-full flex justify-center items-center p-12 gap-12">
          <div>
            <h1 className="text-3xl font-bold">Install system extension</h1>
            <p className="mt-4 text-lg text-slate-500 max-w-xl">
              When you click the button below, then be sure to choose the <b>GRAY</b>
              {` `}
              button to open {systemSettings}.
            </p>
            <Button
              color="primary"
              size="large"
              type="button"
              onClick={() => emit({ case: `primaryBtnClicked` })}
              className="mt-8"
            >
              Start the installation
              <i className="fa-solid fa-arrow-right ml-2" />
            </Button>
          </div>
          <ExpandableImage
            fileName="sys-ext-blocked.png"
            os={os}
            alt="Don't click te blue button!"
            width={800 / 2}
            height={600 / 2}
          />
        </div>
      );
    case `installSysExt_allowInstall`:
      return (
        <div className="h-full flex justify-center items-center p-12 gap-12">
          <div className="flex flex-col">
            <h1 className="text-3xl font-bold">Allow system extenson</h1>
            <p className="my-4 text-lg text-slate-500 max-w-xl">
              Next, in the {systemSettings} app follow the steps shown to allow the
              installation:
            </p>
            <div className="flex flex-col w-80 gap-4 mt-4">
              <Button
                color="primary"
                size="large"
                type="button"
                onClick={() => emit({ case: `primaryBtnClicked` })}
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
                Help, I'm stuck...
              </Button>
            </div>
          </div>
          <ExpandableImage
            fileName="finish-install-sys-ext.gif"
            os={os}
            alt={`Allow system extension install`}
            width={800 / 2}
            height={600 / 2}
          />
        </div>
      );
    case `installSysExt_failed`:
      return (
        <div className="h-full flex flex-col justify-center items-center">
          <h1 className="text-3xl font-bold mb-2">Hmm, somthing didn't work...</h1>
          <p className="text-lg text-slate-500 text-center max-w-2xl">
            Shucks! The system extension did not install correctly. Watch this short video
            for troubleshooting tips.
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
              Skip install for now...
            </Button>
          </div>
        </div>
      );
    case `installSysExt_success`:
      return (
        <div className="h-full flex flex-col justify-center items-center">
          <h1 className="text-3xl font-bold">System extension installed!</h1>
          <p className="text-lg text-slate-500 mt-4 mb-8">
            Hooray, we've confirmed the system extension is <em>ready to go!</em>
          </p>
          <Callout type="info" heading="Good to know:">
            You're past all the hard parts, all that's left it to briefly show you around
            a bit.
          </Callout>
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
      );
    default:
      return <h1>{step}</h1>;
  }
};

export default InstallSysExt;
