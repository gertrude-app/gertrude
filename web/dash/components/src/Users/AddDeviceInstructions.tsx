import React from 'react';
import { Button } from '@shared/components';
import { ComputerDesktopIcon } from '@heroicons/react/24/solid';
import { OnboardingRecommendation } from '../Dashboard/Dashboard';
import ListStep from './ListStep';

interface Props {
  onMainDashboard?: boolean;
  userName: string;
  userId: string;
  startAddDevice: (userId: UUID) => void;
}

const AddDeviceInstructions: React.FC<Props> = ({
  onMainDashboard = false,
  userName,
  userId,
  startAddDevice,
}) => (
  <>
    {onMainDashboard ? (
      <>
        <h1 className="font-inter text-2xl xs:text-3xl lg:text-4xl text-center">
          Congrats on making your first user!
        </h1>
        <p className="text-base xs:text-lg sm:text-xl text-slate-600 text-center mt-4 max-w-xl">
          To finish getting setup, you'll need to do 3 steps:
        </p>
      </>
    ) : (
      <h2 className="mb-8 text-2xl font-bold">Follow these steps to connect a device:</h2>
    )}

    <ol className="flex flex-col gap-4 mt-8">
      <ListStep index={1}>
        On the computer {userName} uses, download the Gertrude Mac app from
        {` `}
        <a href="https://gertrude.app/download" target="_blank" rel="noreferrer">
          https://gertrude.app/download
        </a>
        {` `}
        then install and launch the app.
      </ListStep>
      {onMainDashboard ? (
        <ListStep index={2}>
          Then, from back here inside the parent site, get a one-time user connection code
          by{` `}
          <span
            className="cursor-pointer text-indigo-500"
            onClick={() => startAddDevice(userId)}
          >
            clicking here.
          </span>
        </ListStep>
      ) : (
        <>
          <ListStep index={2}>
            Then, from back here inside the parent site, get a one-time user connection
            code by clicking the button below:
          </ListStep>
          <Button
            type="button"
            onClick={() => startAddDevice(userId)}
            color="primary"
            className="self-center flex items-center gap-2"
          >
            <ComputerDesktopIcon className="h-5" />
            Get connection code
          </Button>
        </>
      )}
      <ListStep index={3}>
        Finally, back on {userName}'s computer, click the Gertrude icon in the menu bar
        and enter the connection code.{` `}
        {!onMainDashboard && `Once the device connects, you will be able to see it here.`}
      </ListStep>
    </ol>
    <div className="flex flex-col-reverse lg:flex-row gap-4 mt-12 w-full">
      <OnboardingRecommendation
        className="flex-grow"
        title={`Get more help`}
        icon={`fa-solid fa-life-ring`}
        href={`https://gertrude.app/contact`}
        openInNewTab
      />
      <OnboardingRecommendation
        className="flex-grow"
        title={`Show me how (90s)`}
        icon={`fa-brands fa-youtube`}
        href={`/`}
        primary
      />
    </div>
  </>
);

export default AddDeviceInstructions;
