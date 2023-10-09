import React, { useContext } from 'react';
import Callout from '../Callout';
import ExpandableImage from '../ExpandableImage';
import * as Onboarding from '../UtilityComponents';
import OnboardingContext from '../OnboardingContext';

interface Props {
  step:
    | 'installSysExt_explain'
    | 'installSysExt_allow'
    | 'installSysExt_allowFiltering'
    | 'installSysExt_failed'
    | 'installSysExt_success';
}

const InstallSysExt: React.FC<Props> = ({ step }) => {
  const { systemSettingsName } = useContext(OnboardingContext);
  switch (step) {
    case `installSysExt_explain`:
      return (
        <Onboarding.Centered>
          <Onboarding.Heading>Just one more step!</Onboarding.Heading>
          <Onboarding.Text className="my-4 max-w-2xl mb-8" centered>
            What gives Gertrude it's superpowers is something called a{` `}
            <b>system extension</b>. 🚀 Because it's so powerful, you have to give it{` `}
            <span className="underline">special permission</span> to do it's job.
          </Onboarding.Text>
          <Callout heading="Good to know:" type="info">
            <p>You can disable and remove the system extension at any time.</p>
          </Callout>
          <Onboarding.PrimaryButton icon="fa-solid fa-arrow-right" className="mt-8">
            Next
          </Onboarding.PrimaryButton>
        </Onboarding.Centered>
      );
    case `installSysExt_allow`:
      return (
        <Onboarding.Centered className="gap-12" direction="row">
          <div className="flex flex-col">
            <Onboarding.Heading>Allow system extenson</Onboarding.Heading>
            <Onboarding.Text className="my-4 max-w-xl">
              Next, in the {systemSettingsName} app follow the steps shown to allow the
              installation:
            </Onboarding.Text>
            <Onboarding.ButtonGroup
              primary="Done"
              secondary={{ text: `Help, I'm stuck...`, shadow: true }}
              className="w-80 mt-4"
            />
          </div>
          <ExpandableImage
            fileName="finish-install-sys-ext.gif"
            alt={`Allow system extension install`}
            width={800 / 2}
            height={600 / 2}
          />
        </Onboarding.Centered>
      );
    case `installSysExt_failed`:
      return (
        <Onboarding.Centered className="h-full flex flex-col justify-center items-center">
          <Onboarding.Heading className="mb-2">
            Hmm, somthing didn't work...
          </Onboarding.Heading>
          <Onboarding.Text className="max-w-2xl" centered>
            Shucks! The system extension did not install correctly. Watch this short video
            for troubleshooting tips.
          </Onboarding.Text>
          <iframe
            className="my-6 rounded-xl"
            width="560"
            height="315"
            src="https://www.youtube-nocookie.com/embed/ytN1HhQX3xo?rel=0"
            title="YouTube video player"
            allowFullScreen
          />
          <Onboarding.ButtonGroup
            primary="Try again"
            secondary={{ text: `Skip install for now...`, shadow: true }}
            className="w-80"
          />
        </Onboarding.Centered>
      );
    case `installSysExt_success`:
      return (
        <Onboarding.Centered>
          <Onboarding.Heading>System extension installed!</Onboarding.Heading>
          <Onboarding.Text className="mt-4 mb-8">
            Hooray, we've confirmed the system extension is <em>ready to go!</em>
          </Onboarding.Text>
          <Callout type="info" heading="Good to know:">
            You're past all the hard parts, all that's left it to briefly show you around
            a bit.
          </Callout>
          <Onboarding.PrimaryButton icon="fa-solid fa-arrow-right" className="mt-8">
            Next
          </Onboarding.PrimaryButton>
        </Onboarding.Centered>
      );
    default:
      return <h1>{step}</h1>;
  }
};

export default InstallSysExt;
