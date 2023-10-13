import React, { useContext, useState } from 'react';
import Callout from '../Callout';
import ExpandableImage from '../ExpandableImage';
import * as Onboarding from '../UtilityComponents';
import OnboardingContext from '../OnboardingContext';
import InformationModal from '../InformationModal';

interface Props {
  step:
    | 'allowScreenshots_required'
    | 'allowScreenshots_grantAndRestart'
    | 'allowScreenshots_failed'
    | 'allowScreenshots_success';
}

const AllowScreenshots: React.FC<Props> = ({ step }) => {
  const [showModal, setShowModal] = useState(false);
  const { systemSettingsName, emit } = useContext(OnboardingContext);
  switch (step) {
    case `allowScreenshots_required`:
      return (
        <Onboarding.Centered>
          <Onboarding.Heading className="text-3xl font-bold">
            Grant screen recording permission
          </Onboarding.Heading>
          <Onboarding.Text className="mt-4 mb-8 max-w-2xl" centered>
            Gertrude needs your permission to record the screen, so it can take
            screenshots of your child’s activity.
          </Onboarding.Text>
          <Callout heading="Good to know:" type="info">
            <ul className="list-disc list-inside ml-2">
              <li>You control if and when we record screenshots</li>
              <li>Your child is shown when their screen is being recorded</li>
            </ul>
          </Callout>
          <Onboarding.ButtonGroup
            primary="Grant permission"
            secondary={{ text: `Skip this step...`, shadow: true }}
            className="mt-8 w-80"
          />
        </Onboarding.Centered>
      );
    case `allowScreenshots_grantAndRestart`:
      return (
        <Onboarding.Centered direction="row" className="space-x-12">
          <InformationModal open={showModal} setOpen={setShowModal}>
            If you can’t find the <b>{systemSettingsName} app</b>, try closing
            applications, moving windows, and checking any additional desktops you may
            have open. Failing that, click the Apple icon () in the far upper left corner
            of your screen, and choose “{systemSettingsName}...” then search for “Privacy
            &amp; Security.” Once you’re in that area, scroll down and select “Screen
            Recording” then follow the steps shown in the animated image below this popup.
            If you’re still stuck,{` `}
            <Onboarding.TextButton onClick={() => emit({ case: `primaryBtnClicked` })}>
              click here
            </Onboarding.TextButton>
            {` `} to watch a short troubleshooting video. Or, it’s OK to skip this step
            for now, and fix it later after contacting us for help.
          </InformationModal>
          <div className="flex flex-col !ml-0">
            <Onboarding.Heading>Allow screenshots</Onboarding.Heading>
            <Onboarding.Text className="max-w-2xl mt-4 mb-8">
              Follow the steps shown, which include <b>quitting Gertrude.</b> This screen
              will open again when it restarts.
            </Onboarding.Text>
            <Onboarding.SecondaryButton
              onClick={() => {
                setShowModal(true);
                emit({
                  case: `infoModalOpened`,
                  step: `allowScreenshots_grantAndRestart`,
                  detail: `helpStuck`,
                });
              }}
            >
              Help, I’m stuck...
            </Onboarding.SecondaryButton>
          </div>
          <ExpandableImage
            fileName="allow-screen-recording.gif"
            width={800 / 1.9}
            height={600 / 1.9}
          />
          <Onboarding.EscapeHatchButton
            onClick={() => emit({ case: `secondaryBtnClicked` })}
          >
            Continue and resolve later &rarr;
          </Onboarding.EscapeHatchButton>
        </Onboarding.Centered>
      );
    case `allowScreenshots_success`:
      return (
        <Onboarding.Centered>
          <div className="flex flex-col items-center bg-white p-12 rounded-3xl shadow-lg shadow-slate-300/30">
            <Onboarding.Heading>Awesome!</Onboarding.Heading>
            <Onboarding.Text className="max-w-xl mt-4" centered>
              Gertrude now has the permission it needs to take screenshots.
            </Onboarding.Text>
            <Onboarding.PrimaryButton icon="fa-solid fa-arrow-right" className="mt-8">
              Next
            </Onboarding.PrimaryButton>
          </div>
        </Onboarding.Centered>
      );
    case `allowScreenshots_failed`:
      return (
        <Onboarding.Centered>
          <Onboarding.Heading>
            <i className="fas fa-exclamation-triangle text-yellow-600 mr-4" />
            Screen recording permission not granted
          </Onboarding.Heading>
          <Onboarding.Text className="mt-2">
            Watch the short video below for more troubleshooting steps.
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
            secondary={{ text: `Skip for now`, shadow: true }}
            className="w-80"
          />
        </Onboarding.Centered>
      );
  }
};

export default AllowScreenshots;
