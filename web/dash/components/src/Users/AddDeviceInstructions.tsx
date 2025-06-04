import { ComputerDesktopIcon } from '@heroicons/react/24/solid';
import { Button } from '@shared/components';
import React from 'react';
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
    <h1 className="font-inter text-2xl xs:text-3xl lg:text-4xl text-center">
      {onMainDashboard ? `Congrats on adding your first child!` : `Nearly there!`}
    </h1>
    <p className="text-base xs:text-lg sm:text-xl text-slate-600 text-center mt-4 max-w-xl mx-auto">
      {onMainDashboard ? (
        <span>
          To finish getting started, you'll need to do <b>2 steps:</b>
        </span>
      ) : (
        <span>
          To start protecting <i className="font-bold">{userName}</i>, you'll need to do 2
          steps:
        </span>
      )}
    </p>

    <ol className="flex flex-col gap-4 mt-8">
      <ListStep index={1}>
        On the computer <b className="underline">{userName}</b> uses, download the
        Gertrude Mac app from
        {` `}
        <a href="https://gertrude.app/download" target="_blank" rel="noreferrer">
          https://gertrude.app/download
        </a>
        {` `}
        then install and launch the app.
      </ListStep>
      <ListStep index={2}>
        A few steps into the welcome wizard, when asked for a <b>connection code</b>, come
        back here and click the button below:
      </ListStep>
      <Button
        size="large"
        type="button"
        onClick={() => startAddDevice(userId)}
        color="primary"
        className="self-center hidden sm:flex items-center gap-2"
      >
        <ComputerDesktopIcon className="h-5" />
        Get connection code
      </Button>
      <Button
        type="button"
        onClick={() => startAddDevice(userId)}
        color="primary"
        className="flex sm:hidden justify-center items-center gap-2"
      >
        <ComputerDesktopIcon className="h-5" />
        Get connection code
      </Button>
    </ol>
    <div className="flex flex-col-reverse lg:flex-row gap-4 mt-12 w-full">
      <OnboardingRecommendation
        className="flex-grow"
        title="Get more help"
        icon="fa-solid fa-life-ring"
        href="https://gertrude.app/contact"
        openInNewTab
      />
      <OnboardingRecommendation
        className="flex-grow"
        title="How-to video (2 min)"
        icon="fa-brands fa-youtube"
        href="https://youtu.be/0GuhxIbYz-4"
        openInNewTab
        primary
      />
    </div>
  </>
);

export default AddDeviceInstructions;
