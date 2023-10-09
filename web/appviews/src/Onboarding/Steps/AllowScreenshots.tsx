import React from 'react';
import { Button } from '@shared/components';
import type { AppEvent, OSGroup } from '../onboarding-store';
import Callout from '../Callout';
import ExpandableImage from '../ExpandableImage';
import * as Onboarding from '../UtilityComponents';

interface Props {
  emit(event: AppEvent): unknown;
  os: OSGroup;
  step:
    | 'allowScreenshots_required'
    | 'allowScreenshots_openSysSettings'
    | 'allowScreenshots_grantAndRestart'
    | 'allowScreenshots_failed'
    | 'allowScreenshots_success';
}

const AllowScreenshots: React.FC<Props> = ({ emit, step, os }) => {
  const systemSettings =
    os === `venturaOrLater` ? `System Settings` : `System Preferences`;
  switch (step) {
    case `allowScreenshots_required`:
      return (
        <Onboarding.Centered>
          <Onboarding.Heading className="text-3xl font-bold">
            Grant screen recording permission
          </Onboarding.Heading>
          <Onboarding.Text className="mt-4 mb-8 max-w-2xl" centered>
            Gertrude needs your permission to record the screen, so it can take
            screenshots of your child's activity.
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
            emit={emit}
            className="mt-8 w-80"
          />
        </Onboarding.Centered>
      );
    case `allowScreenshots_openSysSettings`:
      return (
        <Onboarding.Centered direction="row" className="gap-12">
          <div className="flex flex-col">
            <Onboarding.Heading>Open {systemSettings}</Onboarding.Heading>
            <Onboarding.Text className="max-w-lg mt-4">
              Just now, a system popup should have appeared that looks like this. Find it
              and click{` `}
              <b>Open {systemSettings}.</b>
            </Onboarding.Text>
            <Onboarding.ButtonGroup
              primary="Done"
              secondary={{ text: `I don’t see a popup...`, shadow: true }}
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
    case `allowScreenshots_grantAndRestart`:
      return (
        <Onboarding.Centered>
          <Onboarding.Heading>Allow screenshots</Onboarding.Heading>
          <Onboarding.Text className="max-w-2xl mt-4 mb-16" centered>
            Follow the steps shown below, which include <b>quitting Gertrude.</b> This
            screen will open again when it restarts.
          </Onboarding.Text>
          <ExpandableImage
            fileName="allow-screen-recording.gif"
            os={os}
            alt={`Allow screenshots`}
            width={800 / 1.9}
            height={600 / 1.9}
          />
          <Button
            color="tertiary"
            size="large"
            type="button"
            onClick={() => emit({ case: `primaryBtnClicked` })}
            className="mt-2 translate-y-4"
          >
            Help, I'm still here...
          </Button>
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
            <Onboarding.PrimaryButton
              emit={emit}
              icon="fa-solid fa-arrow-right"
              className="mt-8"
            >
              Next
            </Onboarding.PrimaryButton>
          </div>
        </Onboarding.Centered>
      );
    case `allowScreenshots_failed`:
      return (
        <Onboarding.Centered>
          <div className="flex flex-col items-center border-2 border-slate-200/60 border-dashed p-12 rounded-3xl">
            <Onboarding.Heading>Hmm... something didn't work</Onboarding.Heading>
            <Onboarding.Text className="mt-4">
              We still don't have permission to record the screen. Please try again.
            </Onboarding.Text>
            <Onboarding.ButtonGroup
              primary="Try again"
              secondary={{ text: `Skip this step...`, shadow: true }}
              emit={emit}
              className="mt-8 w-80"
            />
          </div>
        </Onboarding.Centered>
      );
  }
};

export default AllowScreenshots;
