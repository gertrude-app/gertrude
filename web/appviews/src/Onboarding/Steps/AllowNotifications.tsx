import React from 'react';
import type { AppEvent, OSGroup } from '../onboarding-store';
import ExpandableImage from '../ExpandableImage';
import * as Onboarding from '../UtilityComponents';

interface Props {
  emit(event: AppEvent): unknown;
  os: OSGroup;
  step:
    | 'allowNotifications_start'
    | 'allowNotifications_grant'
    | 'allowNotifications_failed';
}

const AllowNotifications: React.FC<Props> = ({ emit, step, os }) => {
  const systemSettings =
    os === `venturaOrLater` ? `System Settings` : `System Preferences`;
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
            primary={{ text: `Open ${systemSettings}`, icon: `fa-solid fa-arrow-right` }}
            secondary={{ text: `Skip this step`, shadow: true }}
            emit={emit}
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
              We just opened the {systemSettings} app. Set Gertrude's notifications to
              {` `}
              <b>Alerts</b> as shown here:
            </Onboarding.Text>
            <Onboarding.ButtonGroup
              primary={{
                text: `Done`,
                icon: `fa-solid fa-arrow-right`,
              }}
              secondary={{ text: `Help...`, shadow: true }}
              emit={emit}
              className="mt-8"
            />
          </div>
          <ExpandableImage
            fileName="allow-notifications.gif"
            os={os}
            alt={`Grant permission`}
            width={800 / 2}
            height={600 / 2}
            showInstructions
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
            primary={{
              text: `Check again`,
              icon: `fa-solid fa-arrow-right`,
            }}
            secondary={{ text: `Skip for now`, shadow: true }}
            emit={emit}
            className="w-80"
          />
        </Onboarding.Centered>
      );
  }
};

export default AllowNotifications;
