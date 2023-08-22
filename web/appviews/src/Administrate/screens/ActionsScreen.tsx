import React, { useState } from 'react';
import { Button } from '@shared/components';
import cx from 'classnames';
import { PillBadge } from '@shared/components';
import type { AppEvent } from '../administrate-store';
import type { FilterState } from '../../lib/shared-types';

interface Props {
  filterState: FilterState;
  installedAppVersion: string;
  newestAvailableVersion: {
    version: string;
    required: boolean;
  };
  userName: string;
  releaseChannel: 'stable' | 'beta' | 'canary';
  quitting: boolean;
  emit(event: AppEvent): unknown;
}

const ActionsScreen: React.FC<Props> = ({
  filterState,
  installedAppVersion,
  newestAvailableVersion,
  userName,
  emit,
  quitting,
  releaseChannel,
}) => {
  const [confirmationModalOpen, setConfirmationModalOpen] = useState(false);
  const [confirmationModalAction, setConfirmationModalAction] = useState<
    'quitApp' | 'stopFilter'
  >(`quitApp`);

  let versionMessage = ``;
  let badgeColor: 'green' | 'yellow' | 'red' = `green`;
  let badgeText = ``;
  if (installedAppVersion === newestAvailableVersion.version) {
    versionMessage = `You're up to date! We'll let you know when the next update is available.`;
    badgeText = `Up to date`;
    badgeColor = `green`;
  } else if (newestAvailableVersion.required) {
    versionMessage = `Please update to Gertrude v${newestAvailableVersion.version} to continue using the app. This is a requred update that contains new fixes and features necessary for your child's safety.`;
    badgeText = `Update required`;
    badgeColor = `red`;
  } else {
    versionMessage = `Gertrude v${newestAvailableVersion.version} is available for download.`;
    badgeText = `Update available`;
    badgeColor = `yellow`;
  }

  return (
    <div className="p-4 h-full flex flex-col justify-between relative">
      <div
        className={cx(
          `w-full h-full left-0 top-0 bg-slate-100 dark:bg-slate-900 z-10 transition-[backdrop-filter,background-color] duration-300 flex justify-center items-center fixed`,
          confirmationModalOpen
            ? `bg-opacity-30 dark:bg-opacity-90 dark:backdrop-blur-sm backdrop-blur-md pointer-events-auto`
            : `bg-opacity-0 dark:bg-opacity-0 backdrop-blur-none pointer-events-none`,
        )}
        onClick={() => setConfirmationModalOpen(false)}
      >
        <div
          className={cx(
            `bg-white dark:bg-slate-800 shadow-lg shadow-slate-300/50 dark:shadow-black/20 rounded-2xl transition-[transform,opacity] duration-300`,
            confirmationModalOpen
              ? `pointer-events-auto`
              : `pointer-events-none scale-75 opacity-0`,
          )}
          onClick={(e) => e.stopPropagation()}
        >
          <div className="p-8">
            <h3 className="font-bold text-xl text-slate-900 dark:text-slate-200 ">
              Are you sure you want to
              {confirmationModalAction === `quitApp`
                ? ` quit Gertrude?`
                : ` stop the filter?`}
            </h3>
            <p className="max-w-md text-sm text-slate-500 dark:text-slate-400 mt-4">
              {confirmationModalAction === `quitApp` // TODO:
                ? `Lorem ipsum dolor sit amet consectetur adipisicing elit. Quos, laboriosam vero optio delectus eius sequi perferendis temporibus ipsa dicta.`
                : `Lorem ipsum dolor sit amet consectetur adipisicing elit. Quos, laboriosam vero optio delectus eius sequi perferendis temporibus ipsa dicta.`}
            </p>
          </div>
          <div className="p-4 bg-slate-50 dark:bg-slate-900/50 rounded-b-2xl flex justify-between space-x-4">
            <Button
              type="button"
              onClick={() => setConfirmationModalOpen(false)}
              color="tertiary"
              className="flex-grow"
            >
              Cancel
            </Button>
            <Button
              type="button"
              onClick={() =>
                emit({
                  case:
                    confirmationModalAction === `quitApp`
                      ? `quitAppClicked`
                      : `stopFilterClicked`,
                })
              }
              color="warning"
              className="flex-grow"
              disabled={confirmationModalAction === `quitApp` && quitting}
            >
              {quitting
                ? `Quitting...`
                : `Yes, ${
                    confirmationModalAction === `quitApp` ? `quit app` : `stop filter`
                  }`}
            </Button>
          </div>
        </div>
      </div>
      <div className="flex flex-col flex-grow">
        <div className="pl-4 flex justify-between items-center mb-2">
          <h1 className="font-bold text-xl text-slate-800 dark:text-slate-300">
            Connected to user{` `}
            <span className="text-slate-900 dark:text-white font-extrabold">
              {userName}
            </span>
          </h1>
          <Button
            type="button"
            size="small"
            onClick={() => emit({ case: `reconnectUserClicked` })}
            color="tertiary"
          >
            Connect to a different user
          </Button>
        </div>
        <div className="border border-slate-200 dark:border-slate-800 rounded-2xl relative flex flex-col justify-between my-4">
          <div className="p-4">
            <PillBadge
              type={badgeColor}
              className="absolute right-2 top-2 w-36 !max-w-none"
            >
              {badgeText}
            </PillBadge>
            <h2 className="text-lg font-semibold text-slate-600 dark:text-slate-300">
              Currently running Gertrude{` `}
              <span className="font-bold text-slate-900 dark:text-white">
                v{installedAppVersion}
              </span>
              {` `}
              and updating to{` `}
              <span className="font-bold text-slate-900 dark:text-white">
                {releaseChannel}
              </span>
              {` `}
              releases.
            </h2>
            <p className="text-slate-500 mt-2">{versionMessage}</p>
          </div>
          <div className="p-4 bg-slate-50 dark:bg-slate-800/50 rounded-b-2xl flex justify-end">
            <Button
              type="button"
              size="small"
              onClick={() => emit({ case: `checkForAppUpdatesClicked` })}
              color="tertiary"
              disabled={installedAppVersion === newestAvailableVersion.version}
            >
              Update Gertrude
            </Button>
          </div>
        </div>
      </div>
      <div className="border border-red-200/70 dark:border-red-500/20 rounded-2xl bg-red-50/20 dark:bg-red-500/5">
        <div className="p-4">
          <h2 className="text-xl font-bold text-red-700 dark:text-red-400">
            Danger zone
          </h2>
          <p className="text-sm mt-2 text-red-700/80 dark:text-red-500/70">
            Actions in this zone either stop all internet filtering or all screenshot and
            keystroke monitoring, and should only be done for troubleshooting purposes.
          </p>
        </div>
        <div className="flex justify-end space-x-4 bg-red-50/30 dark:bg-red-500/5 rounded-b-2xl p-4">
          {filterState.case !== `off` && (
            <Button
              type="button"
              onClick={() => {
                setConfirmationModalAction(`stopFilter`);
                setConfirmationModalOpen(true);
              }}
              color="warning"
            >
              Stop filter
            </Button>
          )}
          <Button
            type="button"
            onClick={() => {
              setConfirmationModalAction(`quitApp`);
              setConfirmationModalOpen(true);
            }}
            color="warning"
          >
            Quit app
          </Button>
        </div>
      </div>
    </div>
  );
};

export default ActionsScreen;
