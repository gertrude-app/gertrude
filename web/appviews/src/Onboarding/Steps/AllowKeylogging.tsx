import React, { useContext, useState } from 'react';
import Callout from '../Callout';
import ExpandableContent from '../ExpandableContent';
import * as Onboarding from '../UtilityComponents';
import assets from '../cdn-assets';
import OnboardingContext from '../OnboardingContext';
import InformationModal from '../InformationModal';
import TellMeMoreButton from '../TellMeMoreButton';

interface Props {
  step: 'allowKeylogging_required' | 'allowKeylogging_grant' | 'allowKeylogging_failed';
}

const AllowKeylogging: React.FC<Props> = ({ step }) => {
  const { systemSettingsName, os, currentStep, emit } = useContext(OnboardingContext);
  const [showModal, setShowModal] = useState(false);
  switch (step) {
    case `allowKeylogging_required`:
      return (
        <Onboarding.Centered className="h-full flex flex-col justify-center items-center">
          <InformationModal open={showModal} setOpen={setShowModal}>
            Having a record of everything your child types can be a powerful form of
            accountability and oversight for you as the parent. We’ll only{` `}
            <b>
              <i>use </i>
            </b>
            this permission if you enable it from the parents website, but it’s important
            that we <i>have the permission ready,</i> so that at any time and from
            anywhere you can turn it on. For example, if your child requests a temporary
            filter suspension, you can instruct Gertrude from wherever you are to record
            their typing <i>only during the filter suspension,</i> provided the permission
            has already been granted.
          </InformationModal>
          <Onboarding.Heading>Now let’s allow keylogging</Onboarding.Heading>
          <Onboarding.Text className="mt-4 mb-8 max-w-3xl" centered>
            Gertrude needs your permission to record what your child types.
            <TellMeMoreButton
              onClick={() => {
                setShowModal(true);
                emit({
                  case: `infoModalOpened`,
                  step: `allowKeylogging_required`,
                  detail: `why?`,
                });
              }}
            >
              Why?
            </TellMeMoreButton>
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
    case `allowKeylogging_grant`:
      return (
        <Onboarding.Centered className="space-x-12" direction="row">
          <InformationModal open={showModal} setOpen={setShowModal}>
            Try closing other applications, moving windows, and checking any additional
            desktops you may have open. Still can’t find it? No problem&mdash;click the
            Apple icon () in the far upper left corner of your screen, choose “
            {systemSettingsName}...” and then search for “Privacy &amp; Security.” Once
            you’re in that area, scroll to and click “Accessibility.” That will put you in
            the <em>same spot</em> as clicking the popup. Still stuck? Just click “Done”
            and you’ll be able to watch a short troubleshooting video.
          </InformationModal>
          <div className="flex flex-col !ml-0">
            <Onboarding.Heading>Allow keylogging</Onboarding.Heading>
            <Onboarding.Text className="max-w-lg mt-4">
              Just now, a system popup should have appeared. Find it and click{` `}
              <b>Open {systemSettingsName},</b> then toggle to grant permission.
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
                    step: `allowKeylogging_grant`,
                    detail: `noPopup`,
                  });
                },
              }}
              className="mt-8 w-80"
            />
          </div>
          <ExpandableContent
            asset={assets.osImg(os, `allow-keylogging`)}
            width={640 / 1.7}
            height={490 / 1.7}
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
          <ExpandableContent
            width={640 * 0.8}
            height={360 * 0.8}
            asset={assets.osVideo(
              os,
              `troubleshoot-keylogging`,
              currentStep === `allowKeylogging_failed`,
            )}
            className="mt-4 mb-6"
            showInstructions={false}
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
