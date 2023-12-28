import React, { useContext, useState } from 'react';
import ExpandableContent from '../ExpandableContent';
import * as Onboarding from '../UtilityComponents';
import OnboardingContext from '../OnboardingContext';
import assets from '../cdn-assets';
import InformationModal from '../InformationModal';

interface Props {
  step:
    | 'allowNotifications_start'
    | 'allowNotifications_grant'
    | 'allowNotifications_failed';
}

const AllowNotifications: React.FC<Props> = ({ step }) => {
  const [showModal, setShowModal] = useState(false);
  const { systemSettingsName, os, emit, currentStep } = useContext(OnboardingContext);
  switch (step) {
    case `allowNotifications_start`:
      return (
        <Onboarding.Centered>
          <Onboarding.Heading>Now let’s allow notifications</Onboarding.Heading>
          <Onboarding.Text className="mt-2 mb-8 max-w-xl" centered>
            Gertrude sends <b>a small number of important notifications</b>, so it’s
            important that your child sees them.
          </Onboarding.Text>
          <img
            src={assets.img(`notifications.png`).url}
            alt="Allow notifications"
            className="rounded-xl mb-8 w-[580px]"
          />
          <Onboarding.ButtonGroup
            primary={`Open ${systemSettingsName}`}
            secondary={{ text: `Skip this step`, shadow: true }}
            direction="row"
          />
        </Onboarding.Centered>
      );
    case `allowNotifications_grant`:
      return (
        <Onboarding.Centered className="space-x-12" direction="row">
          <InformationModal open={showModal} setOpen={setShowModal}>
            If you can’t find the <b>{systemSettingsName} app</b>, try closing
            applications, moving windows, and checking any additional desktops you may
            have open. Failing that, click the Apple icon () in the far upper left corner
            of your screen, and choose “{systemSettingsName}...” then search for
            “Notifications.” Once you’re in the Notifications area, follow the steps shown
            in the animated image below this popup. If you’re still stuck,{` `}
            <Onboarding.TextButton>click here</Onboarding.TextButton>
            {` `}to watch a short troubleshooting video.
          </InformationModal>
          <div className="flex flex-col !ml-0">
            <Onboarding.Heading>Set notifications to “Alerts”</Onboarding.Heading>
            <Onboarding.Text className="mt-4 max-w-xl">
              We just opened the {systemSettingsName} app. Set Gertrude’s notifications to
              {` `}
              <b>Alerts</b> as shown in the image to the right.
            </Onboarding.Text>
            <Onboarding.ButtonGroup
              primary="Done"
              secondary={{
                text: `Help, I’m stuck...`,
                shadow: true,
                onClick: () => {
                  setShowModal(true);
                  emit({
                    case: `infoModalOpened`,
                    step: `allowNotifications_grant`,
                    detail: `help`,
                  });
                },
              }}
              className="mt-8"
            />
          </div>
          <ExpandableContent
            // asset={assets.os(os).img(`allow-notifications.gif`)}
            asset={[
              { duration: 3, asset: assets.os(os).img(`allow-notifications.gif`) },
              { duration: 2, asset: assets.os(os).img(`allow-keylogging.gif`) },
              { duration: 1, asset: assets.os(os).img(`allow-screen-recording.gif`) },
            ]}
            width={800 / 2}
            height={600 / 2}
          />
        </Onboarding.Centered>
      );
    case `allowNotifications_failed`:
      return (
        <Onboarding.Centered>
          <Onboarding.Heading>
            <i className="fas fa-exclamation-triangle text-yellow-600 mr-4" />
            Notifications are still not allowed
          </Onboarding.Heading>
          <Onboarding.Text className="mt-2">
            Watch the short video below for more troubleshooting steps.
          </Onboarding.Text>
          <ExpandableContent
            width={640 * 0.8}
            height={360 * 0.8}
            asset={assets.osVideo(
              os,
              `troubleshoot-notifications`,
              currentStep === `allowNotifications_failed`,
            )}
            className="mt-4 mb-6"
            showInstructions={false}
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

export default AllowNotifications;
