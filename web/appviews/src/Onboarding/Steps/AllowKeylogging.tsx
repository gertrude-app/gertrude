import React, { useContext, useState } from 'react';
import Callout from '../Callout';
import ExpandableImage from '../ExpandableImage';
import * as Onboarding from '../UtilityComponents';
import OnboardingContext from '../OnboardingContext';
import InformationModal from '../InformationModal';

interface Props {
  step:
    | 'allowKeylogging_required'
    | 'allowKeylogging_openSysSettings'
    | 'allowKeylogging_grant'
    | 'allowKeylogging_failed';
}

const AllowKeylogging: React.FC<Props> = ({ step }) => {
  const { systemSettingsName, emit } = useContext(OnboardingContext);
  const [showModal, setShowModal] = useState(false);
  switch (step) {
    case `allowKeylogging_required`:
      return (
        <Onboarding.Centered className="h-full flex flex-col justify-center items-center">
          <Onboarding.Heading>Now let’s allow keylogging</Onboarding.Heading>
          <Onboarding.Text className="mt-4 mb-8 max-w-2xl" centered>
            Gertrude needs your permission to record what your child types
          </Onboarding.Text>
          <Callout heading="Good to know:" type="info">
            <ul className="list-disc list-inside ml-2">
              <li>You control if and when we record typing</li>
              <li>Your child is shown when their typing is being recorded</li>
              <li>
                We can’t record passwords, credit card numbers, or other sensitive info
              </li>
            </ul>
          </Callout>
          <Onboarding.ButtonGroup
            primary="Grant permission"
            secondary={{ text: `Skip this step...`, shadow: true }}
            className="mt-8 w-80"
          />
        </Onboarding.Centered>
      );
    case `allowKeylogging_openSysSettings`:
      return (
        <Onboarding.Centered className="space-x-12" direction="row">
          <InformationModal open={showModal} setOpen={setShowModal}>
            Try closing other applications, moving windows, and checking any additional
            desktops you may have open. Still can’t find it? No problem&mdash;click the
            Apple icon () in the far upper left corner of your screen, choose “
            {systemSettingsName}...” and then search for “Privacy &amp; Security.” Once
            you’re in that area, scroll to and click “Accessibility.” That will put you in
            the <em>same spot</em> as clicking the popup.
          </InformationModal>
          <div className="flex flex-col !ml-0">
            <Onboarding.Heading>Open {systemSettingsName}</Onboarding.Heading>
            <Onboarding.Text className="max-w-lg mt-4">
              Just now, a system popup should have appeared that looks like this. Find it
              and click{` `}
              <b>Open {systemSettingsName}.</b>
            </Onboarding.Text>
            <Onboarding.ButtonGroup
              primary="Done"
              secondary={{
                text: `I don’t see a popup...`,
                shadow: true,
                onClick: () => {
                  setShowModal(true);
                  emit({
                    case: `infoModalOpened`,
                    step: `allowKeylogging_openSysSettings`,
                    detail: `noPopup`,
                  });
                },
              }}
              className="mt-8 w-80"
            />
          </div>
          <ExpandableImage
            fileName="accessibility-access.png"
            width={640 / 2}
            height={490 / 2}
          />
        </Onboarding.Centered>
      );
    case `allowKeylogging_grant`:
      return (
        <Onboarding.Centered>
          <Onboarding.Heading>Allow keylogging</Onboarding.Heading>
          <Onboarding.Text className="max-w-xl mt-4 mb-16" centered>
            Now, in the {systemSettingsName} app, follow the steps shown below.
          </Onboarding.Text>
          <ExpandableImage
            fileName="allow-keylogging.png"
            width={900 / 2}
            height={650 / 2}
          />
          <Onboarding.ButtonGroup
            direction="row"
            primary="Done"
            secondary={{ text: `Help, I'm having trouble...`, shadow: true }}
            className="mt-8"
          />
        </Onboarding.Centered>
      );
    case `allowKeylogging_failed`:
      return (
        <Onboarding.Centered>
          <Onboarding.Heading className="mb-2">
            <i className="fas fa-exclamation-triangle text-yellow-600 mr-4" />
            Keylogging permission not granted
          </Onboarding.Heading>
          <Onboarding.Text className="max-w-2xl" centered>
            Watch the short video below for troubleshooting steps:
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
            primary="Try recheck"
            secondary={{ text: `Skip this for now...`, shadow: true }}
            className="w-80"
          />
        </Onboarding.Centered>
      );
  }
};

export default AllowKeylogging;
