import React from 'react';
import type { AppEvent, OSGroup } from '../onboarding-store';
import Callout from '../Callout';
import ExpandableImage from '../ExpandableImage';
import * as Onboarding from '../UtilityComponents';

interface Props {
  emit(event: AppEvent): unknown;
  os: OSGroup;
  step:
    | 'allowKeylogging_required'
    | 'allowKeylogging_openSysSettings'
    | 'allowKeylogging_grant'
    | 'allowKeylogging_failed';
}

const AllowKeylogging: React.FC<Props> = ({ emit, step, os }) => {
  const systemSettings =
    os === `venturaOrLater` ? `System Settings` : `System Preferences`;
  switch (step) {
    case `allowKeylogging_required`:
      return (
        <Onboarding.Centered className="h-full flex flex-col justify-center items-center">
          <Onboarding.Heading>Now let's allow keylogging</Onboarding.Heading>
          <Onboarding.Text className="mt-4 mb-8 max-w-2xl" centered>
            Gertrude needs your permission to record what your child types
          </Onboarding.Text>
          <Callout heading="Good to know:" type="info">
            <ul className="list-disc list-inside ml-2">
              <li>You control if and when we record typing</li>
              <li>Your child is shown their typing is being recorded</li>
              <li>
                We can't record passwords, credit card numbers, or other sensitive info
              </li>
            </ul>
          </Callout>
          <Onboarding.ButtonGroup
            primary={{
              text: `Grant permission`,
              icon: `fa-solid fa-arrow-right`,
            }}
            secondary={{ text: `Skip this step...`, shadow: true }}
            emit={emit}
            className="mt-8 w-80"
          />
        </Onboarding.Centered>
      );
    case `allowKeylogging_openSysSettings`:
      return (
        <Onboarding.Centered className="gap-12" direction="row">
          <div className="flex flex-col">
            <Onboarding.Heading>Open {systemSettings}</Onboarding.Heading>
            <Onboarding.Text className="max-w-lg mt-4">
              Just now, a system popup should have appeared that looks like this. Find it
              and click{` `}
              <b>Open {systemSettings}.</b>
            </Onboarding.Text>
            <Onboarding.ButtonGroup
              primary={{
                text: `Done`,
                icon: `fa-solid fa-arrow-right`,
              }}
              secondary={{ text: `Can't find the popup...`, shadow: true }}
              emit={emit}
              className="mt-8 w-80"
            />
          </div>
          <ExpandableImage
            fileName="accessibility-access.png"
            os={os}
            alt={`Grant permission`}
            width={640 / 2}
            height={490 / 2}
          />
        </Onboarding.Centered>
      );
    case `allowKeylogging_grant`:
      return (
        <Onboarding.Centered>
          <Onboarding.Heading>Allow keylogging</Onboarding.Heading>
          <Onboarding.Text className="max-w-xl mt-4 mb-8" centered>
            Now, in the {systemSettings} app, follow the steps shown below.
          </Onboarding.Text>
          <ExpandableImage
            fileName="screen-recording-add-gertrude.gif"
            os={os}
            alt={`Grant permission`}
            width={900 / 2}
            height={650 / 2}
          />
          <Onboarding.ButtonGroup
            primary={{
              text: `Done`,
              icon: `fa-solid fa-arrow-right`,
            }}
            secondary={{ text: `Help, I'm having trouble...`, shadow: true }}
            emit={emit}
            className="mt-8 w-80"
          />
        </Onboarding.Centered>
      );
    case `allowKeylogging_failed`:
      return (
        <Onboarding.Centered>
          <Onboarding.Heading className="mb-2">
            Hmm, somthing didn't work...
          </Onboarding.Heading>
          <Onboarding.Text className="max-w-2xl" centered>
            Shucks! We still don't seem to have the permission we need. Watch the short
            video below for troubleshooting steps:
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
              text: `Done, recheck`,
              icon: `fa-solid fa-arrow-right`,
            }}
            secondary={{ text: `Skip this for now...`, shadow: true }}
            emit={emit}
            className="w-80"
          />
        </Onboarding.Centered>
      );
  }
};

export default AllowKeylogging;
