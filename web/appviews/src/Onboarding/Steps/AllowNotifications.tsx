import React, { useContext } from 'react';
import ExpandableImage from '../ExpandableImage';
import * as Onboarding from '../UtilityComponents';
import OnboardingContext from '../OnboardingContext';

interface Props {
  step:
    | 'allowNotifications_start'
    | 'allowNotifications_grant'
    | 'allowNotifications_failed';
}

const AllowNotifications: React.FC<Props> = ({ step }) => {
  const { systemSettingsName } = useContext(OnboardingContext);
  switch (step) {
    case `allowNotifications_start`:
      return (
        <Onboarding.Centered>
          <Onboarding.Heading>Now let's allow notifications</Onboarding.Heading>
          <Onboarding.Text className="mt-2 mb-8 max-w-xl" centered>
            Gertrude sends <b>a small number of important notifications</b>, so it's
            important that your child sees them.
          </Onboarding.Text>
          <img
            src="https://gertrude.nyc3.digitaloceanspaces.com/appview-assets/onboarding/notification.png"
            alt="Allow notifications"
            className="rounded-xl mb-8"
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
        <Onboarding.Centered className="gap-12" direction="row">
          <div className="flex flex-col">
            <Onboarding.Heading>Set notifications to "Alerts"</Onboarding.Heading>
            <Onboarding.Text className="mt-4 max-w-xl">
              We just opened the {systemSettingsName} app. Set Gertrude's notifications to
              {` `}
              <b>Alerts</b> as shown here:
            </Onboarding.Text>
            <Onboarding.ButtonGroup
              primary="Done"
              secondary={{ text: `Help...`, shadow: true }}
              className="mt-8"
            />
          </div>
          <ExpandableImage
            fileName="allow-notifications.gif"
            alt={`Grant permission`}
            width={800 / 2}
            height={600 / 2}
          />
        </Onboarding.Centered>
      );
    case `allowNotifications_failed`:
      return (
        <Onboarding.Centered>
          <Onboarding.Heading>
            Shucks, the notifications still don't seem right
          </Onboarding.Heading>
          <Onboarding.Text className="mt-2">
            Watch the video for more information.
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
            primary="Check again"
            secondary={{ text: `Skip for now`, shadow: true }}
            className="w-80"
          />
        </Onboarding.Centered>
      );
  }
};

export default AllowNotifications;
