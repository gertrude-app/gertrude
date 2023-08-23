import React from 'react';
import { Button, PillBadge } from '@shared/components';
import cx from 'classnames';
import type { AppEvent, ViewAction } from '../administrate-store';

interface Props {
  filterRunning: boolean;
  installedAppVersion: string;
  availableAppUpdate?: { semver: string; required: boolean };
  userName?: string;
  releaseChannel: 'stable' | 'beta' | 'canary';
  quitting: boolean;
  dangerZoneModal: 'hidden' | 'stopFilter' | 'quitApp';
  emit(event: AppEvent): unknown;
  dispatch(action: ViewAction): unknown;
}

const ActionsScreen: React.FC<Props> = ({
  filterRunning,
  installedAppVersion,
  availableAppUpdate,
  dangerZoneModal,
  userName,
  emit,
  quitting,
  releaseChannel,
  dispatch,
}) => {
  const update = updateData(availableAppUpdate);
  return (
    <div className="p-4 h-full flex flex-col justify-between relative">
      <div
        className={cx(
          `w-full h-full left-0 top-0 bg-slate-100 dark:bg-slate-900 z-10 transition-[backdrop-filter,background-color] duration-300 flex justify-center items-center fixed`,
          dangerZoneModal !== `hidden`
            ? `bg-opacity-30 dark:bg-opacity-90 dark:backdrop-blur-sm backdrop-blur-md pointer-events-auto`
            : `bg-opacity-0 dark:bg-opacity-0 backdrop-blur-none pointer-events-none`,
        )}
        onClick={() => dispatch({ type: `dangerZoneModalDismissed` })}
      >
        <div
          className={cx(
            `bg-white dark:bg-slate-800 shadow-lg shadow-slate-300/50 dark:shadow-black/20 rounded-2xl transition-[transform,opacity] duration-300`,
            dangerZoneModal !== `hidden`
              ? `pointer-events-auto`
              : `pointer-events-none scale-75 opacity-0`,
          )}
          onClick={(e) => e.stopPropagation()}
        >
          <div className="p-8">
            <h3 className="font-bold text-xl text-slate-900 dark:text-slate-200 ">
              Are you sure you want to
              {dangerZoneModal === `quitApp` ? ` quit Gertrude?` : ` stop the filter?`}
            </h3>
            <p className="max-w-md text-sm text-slate-500 dark:text-slate-400 mt-4">
              {dangerZoneModal === `quitApp`
                ? `Quitting the app stops all screenshot and keystroke monitoring. This is usually only necessary when uninstalling or troubleshooting.`
                : `Stopping the filter gives all users on this computer unrestricted internet access. If you want to temporarily suspend the filter, use the "Suspend filter" button in the main menubar dropdown instead.`}
            </p>
          </div>
          <div className="p-4 bg-slate-50 dark:bg-slate-900/50 rounded-b-2xl flex justify-between space-x-4">
            <Button
              type="button"
              onClick={() => dispatch({ type: `dangerZoneModalDismissed` })}
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
                    dangerZoneModal === `quitApp`
                      ? `confirmQuitAppClicked`
                      : `confirmStopFilterClicked`,
                })
              }
              color="warning"
              className="flex-grow"
              disabled={dangerZoneModal === `quitApp` && quitting}
            >
              {quitting
                ? `Quitting...`
                : `I understand, ${
                    dangerZoneModal === `quitApp` ? `quit the app` : `stop the filter`
                  }`}
            </Button>
          </div>
        </div>
      </div>
      <div className="flex flex-col flex-grow">
        <div className="border border-slate-200 dark:border-slate-800 rounded-2xl relative flex flex-col justify-between mb-3.5">
          <PillBadge
            type={update.badgeColor}
            className="absolute right-2 top-2 w-36 !max-w-none"
          >
            {update.badgeText}
          </PillBadge>
          <div className="p-4 pt-3">
            <h2 className="text-lg font-semibold text-slate-600 dark:text-slate-300">
              Currently running Gertrude version{` `}
              <span className="font-bold *font-mono text-violet-700 dark:text-violet-400">
                {installedAppVersion}
              </span>
            </h2>
            <p className="text-slate-500 mt-2">{update.versionMessage}</p>
          </div>
          <div className="p-3 bg-slate-50 dark:bg-slate-800/50 rounded-b-2xl flex justify-end items-center">
            <p
              className={cx(
                `text-slate-500 opacity-80 italic ml-3 flex-grow`,
                releaseChannel === `stable` && `hidden`,
              )}
            >
              <i className="fas fa-flask mr-2" />
              Release channel: <b>{releaseChannel}</b>
            </p>
            <Button
              type="button"
              size="small"
              onClick={() => emit({ case: `updateAppNowClicked` })}
              color="tertiary"
              disabled={!availableAppUpdate}
            >
              <i className="fas fa-sync-alt mr-2" />
              Update now
            </Button>
          </div>
        </div>
        {userName !== undefined && (
          <div className="border border-slate-200 dark:border-slate-800 rounded-2xl relative flex flex-col justify-between">
            <div className="p-4 pt-3">
              <h2 className="text-lg font-semibold text-slate-600 dark:text-slate-300">
                Connected to child:{` `}
                <span className="font-bold *font-mono text-violet-700 dark:text-violet-400">
                  {userName}
                </span>
              </h2>
              <p className="text-slate-500 mt-2">
                Disconnect if you want to connect a different child.
              </p>
            </div>
            <div className="p-3 bg-slate-50 dark:bg-slate-800/50 rounded-b-2xl flex justify-end">
              <Button
                type="button"
                size="small"
                onClick={() => emit({ case: `disconnectUserClicked` })}
                color="tertiary"
              >
                <i className="fa fa-scissors mr-2" />
                Disconnect
              </Button>
            </div>
          </div>
        )}
      </div>
      <div className="border border-red-200/70 dark:border-red-500/20 rounded-2xl bg-red-50/20 dark:bg-red-500/5">
        <div className="p-4 pt-3">
          <h2 className="text-xl font-bold text-red-700 dark:text-red-400">
            Danger zone
          </h2>
          <p className="mt-2 text-red-700/70 dark:text-red-400/50">
            These actions disable Gertrude&lsquo;s protections. Use only for
            troubleshooting or uninstalling.
          </p>
        </div>
        <div className="flex justify-end space-x-4 bg-red-50/30 dark:bg-red-500/5 rounded-b-2xl p-3">
          {filterRunning && (
            <Button
              type="button"
              size="small"
              onClick={() => dispatch({ type: `dangerZoneStopFilterClicked` })}
              color="warning"
            >
              Stop filter
            </Button>
          )}
          <Button
            type="button"
            size="small"
            onClick={() => dispatch({ type: `dangerZoneQuitAppClicked` })}
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

function updateData(available?: { semver: string; required: boolean }): {
  badgeColor: 'green' | 'yellow' | 'red';
  badgeText: string;
  versionMessage: React.ReactNode;
} {
  if (!available) {
    return {
      badgeColor: `green`,
      badgeText: `Up to date`,
      versionMessage: `We'll let you know when the next update is available.`,
    };
  } else if (available.required) {
    return {
      badgeColor: `red`,
      badgeText: `Update required`,
      versionMessage: (
        <>
          Update to required version <b>{available.semver}</b> as soon as possible.
        </>
      ),
    };
  } else {
    return {
      badgeColor: `yellow`,
      badgeText: `Update available`,
      versionMessage: `Gertrude version ${available.semver} is available for download.`,
    };
  }
}
