import React, { useContext } from 'react';
import Callout from '../Callout';
import ExpandableContent from '../ExpandableContent';
import * as Onboarding from '../UtilityComponents';
import assets from '../cdn-assets';
import OnboardingContext from '../OnboardingContext';

interface Props {
  step:
    | `installSysExt_explain`
    | `installSysExt_trick`
    | `installSysExt_allow`
    | `installSysExt_failed`
    | `installSysExt_success`;
}

const InstallSysExt: React.FC<Props> = ({ step }) => {
  const { osVersion, currentStep } = useContext(OnboardingContext);
  switch (step) {
    case `installSysExt_explain`:
      return (
        <Onboarding.Centered>
          <Onboarding.Heading>Just one more step!</Onboarding.Heading>
          <Onboarding.Text className="my-4 max-w-2xl mb-8" centered>
            What gives Gertrude its superpowers is something called a{` `}
            <b>system extension</b>. 🚀 Because it’s so powerful, you have to give it{` `}
            <span className="underline">special permission</span> to do its job.
          </Onboarding.Text>
          <Callout heading="Good to know:" type="info">
            <p>You can disable and remove the system extension at any time.</p>
          </Callout>
          <Onboarding.PrimaryButton icon="fa-solid fa-arrow-right" className="mt-8">
            Next
          </Onboarding.PrimaryButton>
        </Onboarding.Centered>
      );
    case `installSysExt_trick`:
      return (
        <Onboarding.Centered className="space-x-12" direction="row">
          <div className="flex flex-col">
            <Onboarding.Heading className="mb-2">
              {osVersion.name !== `catalina` && (
                <span className="text-4xl inline-block translate-y-1 mr-3">🥸</span>
              )}
              Don’t get tricked!
            </Onboarding.Heading>
            <Onboarding.Text className="my-4 max-w-xl">
              Watch out! The <b>next step</b> is easy to mess up, because you should{` `}
              <b className="underline">NOT</b> click the{` `}
              <em>big, highlighted OK button.</em>
            </Onboarding.Text>
            <Onboarding.PrimaryButton icon="fa-solid fa-arrow-right" className="mt-8">
              Got it, I’m ready
            </Onboarding.PrimaryButton>
          </div>
          <ExpandableContent
            asset={assets.osImg(osVersion.name, `sys-ext-install-trick`)}
            width={800 / 2}
            height={600 / 2}
          />
        </Onboarding.Centered>
      );
    case `installSysExt_allow`:
      return (
        <Onboarding.Centered className="space-x-12" direction="row">
          <div className="flex flex-col">
            <Onboarding.Heading>Allow system extension</Onboarding.Heading>
            <Onboarding.Text className="my-4 max-w-xl">
              You should see a system popup now. Follow the steps shown to allow the
              installation:
            </Onboarding.Text>
            <Onboarding.ButtonGroup
              primary="Done"
              secondary={{ text: `Help, I'm stuck...`, shadow: true }}
              className="w-80 mt-4"
            />
          </div>
          <ExpandableContent
            asset={assets.osImg(osVersion.name, `install-sys-ext`)}
            width={800 / 2}
            height={600 / 2}
          />
        </Onboarding.Centered>
      );
    case `installSysExt_failed`:
      return (
        <Onboarding.Centered className="h-full flex flex-col justify-center items-center">
          <Onboarding.Heading className="mb-2">
            <i className="fas fa-exclamation-triangle text-yellow-600 mr-4" />
            Hmm, something didn’t work...
          </Onboarding.Heading>
          <Onboarding.Text className="max-w-2xl" centered>
            Shucks! The system extension did not install correctly. Watch this short video
            for troubleshooting tips.
          </Onboarding.Text>
          <ExpandableContent
            width={640 * 0.8}
            height={360 * 0.8}
            asset={assets.osVideo(
              osVersion.name,
              `troubleshoot-sys-ext-install`,
              currentStep === `installSysExt_failed`,
            )}
            className="mt-4 mb-6"
            showInstructions={false}
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
            Hooray, we’ve confirmed the system extension is <em>ready to go!</em>
          </Onboarding.Text>
          <Callout type="info" heading="Good to know:">
            You’re past all the hard parts, all that’s left is to briefly show you around
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
