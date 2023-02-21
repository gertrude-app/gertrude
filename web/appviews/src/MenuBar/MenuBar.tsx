import React from 'react';
import cx from 'classnames';
import ClockRotateLeft from '../Icons/ClockRotateLeft';
import TowerBroadcast from '../Icons/TowerBroadcast';
import Binoculars from '../Icons/Binoculars';
import Keyboard from '../Icons/Keyboard';
import Gear from '../Icons/Gear';
import ArrowRotateRight from '../Icons/ArrowRotateRight';

type FilterState =
  | { state: 'off' }
  | { state: 'on' }
  | { state: 'suspended'; expiration: string };

type Props =
  | { state: 'notConnected' }
  | {
      state: 'connected';
      recordingKeystrokes: boolean;
      recordingScreenshots: boolean;
      filterState: FilterState;
    };

const MenuBar: React.FC<Props> = (props) => {
  if (props.state === `connected`) {
    let badgeColors = ``;
    switch (props.filterState.state) {
      case `off`:
        badgeColors =
          `bg-red-500 dark:bg-red-500/30 dark:border dark:border-red-500/70 dark:text-red-200`;
        break;
      case `suspended`:
        badgeColors =
          `bg-yellow-500 dark:bg-yellow-500/30 dark:border dark:border-yellow-500/70 dark:text-yellow-200`;
        break;
      default:
        badgeColors =
          `bg-green-500 dark:bg-green-500/30 dark:border dark:border-green-500/70 dark:text-green-300`;
        break;
    }

    return (
      <div className="p-3 select-none flex flex-col h-full">
        <div className="bg-white/20 dark:bg-white/5 shadow-md px-3 py-2 rounded-xl border-[0.5px] border-white/30 dark:border-white/20">
          <div className="flex justify-between items-center">
            <h3 className="text-black dark:text-white font-medium">Internet filter</h3>
            <span
              className={cx(`text-white px-3 py-0 rounded-full font-medium`, badgeColors)}
            >
              {props.filterState.state}
            </span>
          </div>
          {props.filterState.state === `suspended` && (
            <div className="mt-1 -mb-0.5 flex justify-between items-center pr-0">
              <p className="text-sm text-black/70 dark:text-white/70">
                Filter will resume {props.filterState.expiration}
              </p>
              <button className="text-black/60 dark:text-white/60 hover:text-black/90 dark:hover:text-white/90 font-medium transition duration-100">
                resume
              </button>
            </div>
          )}
        </div>
        <div className="flex mt-3 space-x-3">
          <button className="flex-grow shadow-md transition duration-100 hover:bg-white/30 dark:hover:bg-white/10 px-4 py-3 space-x-5 bg-white/20 dark:bg-white/5 border-[0.5px] border-white/30 dark:border-white/20 rounded-xl w-1/2 flex justify-start items-center flex-row">
            <TowerBroadcast className="h-5 shrink-0 text-black/70 dark:text-white/80" />
            <p className="text-sm font-medium text-left leading-5 dark:text-white">
              View network requests
            </p>
          </button>
          <button className="flex-grow shadow-md transition duration-100 hover:bg-white/30 dark:hover:bg-white/10 px-4 py-3 space-x-5 bg-white/20 dark:bg-white/5 border-[0.5px] border-white/30 dark:border-white/20 rounded-xl w-1/2 flex justify-start items-center flex-row">
            <ClockRotateLeft className="h-5 shrink-0 text-black/70 dark:text-white/80" />
            <p className="text-sm font-medium text-left leading-5 dark:text-white">
              Suspend filter
            </p>
          </button>
        </div>
        <div className="flex justify-between flex-grow mt-3 space-x-3">
          <div className="flex flex-col justify-center items-center bg-white/20 dark:bg-white/5 p-3 rounded-lg shadow-md border-[0.5px] border-white/30 dark:border-white/20 w-1/2">
            <div className="flex justify-center items-center space-x-3 mb-1">
              <div
                className={cx(
                  `rounded-full w-10 h-10 flex justify-center items-center`,
                  props.recordingScreenshots
                    ? `bg-indigo-300/40 dark:bg-indigo-600/50 text-indigo-600 dark:text-indigo-300`
                    : `bg-black/5 dark:bg-white/5 text-black/30 dark:text-white/30`,
                )}
              >
                <Binoculars className="w-5" />
              </div>
              <div
                className={cx(
                  `rounded-full w-10 h-10 flex justify-center items-center`,
                  props.recordingKeystrokes
                    ? `bg-indigo-300/40 dark:bg-indigo-600/50 text-indigo-600 dark:text-indigo-300`
                    : `bg-black/5 dark:bg-white/5 text-black/30 dark:text-white/30`,
                )}
              >
                <Keyboard className="w-5" />
              </div>
            </div>
            {props.recordingKeystrokes && (
              <p className="text-xs mt-0.5 text-center italic text-black/50 dark:text-white/50">
                Keystrokes are being monitored
              </p>
            )}
            {props.recordingScreenshots && (
              <p className="text-xs mt-0.5 text-center italic text-black/50 dark:text-white/50">
                Screen is being monitored
              </p>
            )}
          </div>
          <div className="flex flex-col justify-center items-center space-y-1 w-1/2">
            <button className="flex items-center font-medium text-black/80 dark:text-white/80 transition duration-100 hover:bg-white/20 dark:hover:bg-white/10 hover:text-black dark:hover:text-white px-4 py-0.5 rounded-lg">
              <ArrowRotateRight className="w-3.5 mr-2" />
              Refresh rules
            </button>
            <button className="flex items-center font-medium text-black/80 dark:text-white/80 transition duration-100 hover:bg-white/20 dark:hover:bg-white/10 hover:text-black dark:hover:text-white px-4 py-0.5 rounded-lg">
              <Gear className="w-3.5 mr-2" />
              Administrate
            </button>
          </div>
        </div>
      </div>
    );
  }
  return <div>connect a device</div>;
};

export default MenuBar;
