import React from 'react';
import cx from 'classnames';
import { Logo } from '@shared/components';
import type { AppState, ViewState, AppEvent, ViewAction } from './menubar-store';
import type { PropsOf } from '../lib/store';
import ClockRotateLeft from '../Icons/ClockRotateLeft';
import TowerBroadcast from '../Icons/TowerBroadcast';
import Binoculars from '../Icons/Binoculars';
import Keyboard from '../Icons/Keyboard';
import Gear from '../Icons/Gear';
import ArrowRotateRight from '../Icons/ArrowRotateRight';
import Laptop from '../Icons/Laptop';
import { containerize } from '../lib/store';
import FilterBadge, { FilterStateBadge } from './FilterBadge';
import store from './menubar-store';

type Props = PropsOf<AppState, ViewState, AppEvent, ViewAction>;

export const MenuBar: React.FC<Props> = ({
  connectionCode,
  emit,
  dispatch,
  ...props
}) => {
  if (props.case === `enteringConnectionCode`) {
    return (
      <MenuBarSized className="p-3">
        <form
          onSubmit={(e) => {
            e.preventDefault();
            emit({ case: `connectSubmit`, code: Number(connectionCode) });
          }}
        >
          <input
            type="text"
            value={connectionCode}
            autoFocus
            onChange={(e) =>
              dispatch({ type: `connectionCodeUpdated`, code: e.target.value })
            }
          />
          <button type="submit" disabled={connectionCode.match(/^\d{6}$/) === null}>
            {connectionCode.match(/^\d{6}$/) === null
              ? `invalid state, disable`
              : `Submit`}
          </button>
        </form>
      </MenuBarSized>
    );
  }

  if (props.case === `connecting`) {
    return <MenuBarSized>Connecting...</MenuBarSized>;
  }

  if (props.case === `connectionFailed`) {
    return (
      <MenuBarSized className="p-3">
        <h1>Error</h1>
        <p className="text-red-500">{props.error}</p>
        <div className="flex gap-4">
          <button className="border bg-white">Try again (primary)</button>
          <button className="border bg-white">Get help (secondary)</button>
        </div>
      </MenuBarSized>
    );
  }

  if (props.case === `connectionSucceded`) {
    return (
      <MenuBarSized>
        connected to user: {props.userName}
        {` `}
        <button onClick={() => emit({ case: `welcomeAdminClicked` })}>go to admin</button>
      </MenuBarSized>
    );
  }

  if (props.case === `connected`) {
    return (
      <MenuBarSized className="p-3 select-none flex flex-col">
        <div className="bg-white/20 dark:bg-white/5 shadow-md px-3 py-2 rounded-xl border-[0.5px] border-white/30 dark:border-white/20">
          <div className="flex items-center space-x-1.5">
            <h3 className="text-black dark:text-white font-medium grow">
              Internet filter
            </h3>
            {props.filterState.case === `off` && (
              <FilterBadge
                color="grey"
                onClick={() => emit({ case: `turnOnFilterClicked` })}
              >
                Turn on
              </FilterBadge>
            )}
            {props.filterState.case === `suspended` && (
              <FilterBadge
                color="grey"
                onClick={() => emit({ case: `resumeFilterClicked` })}
              >
                Resume
              </FilterBadge>
            )}
            <FilterStateBadge state={props.filterState.case} />
          </div>
          {props.filterState.case === `suspended` && (
            <p className="mt-1 italic text-sm text-black/70 dark:text-white/70">
              Resuming {props.filterState.expiration}
            </p>
          )}
        </div>
        <div className="flex mt-3 space-x-3">
          <button
            onClick={() => emit({ case: `viewNetworkTrafficClicked` })}
            className="flex-grow shadow-md transition duration-100 hover:bg-white/30 dark:hover:bg-white/10 px-4 py-3 space-x-5 bg-white/20 dark:bg-white/5 border-[0.5px] border-white/30 dark:border-white/20 rounded-xl w-1/2 flex justify-start items-center flex-row"
          >
            <TowerBroadcast className="h-5 w-6 shrink-0 text-black/70 dark:text-white/80" />
            <p className="text-sm font-medium text-left dark:text-white leading-tight">
              View network requests
            </p>
          </button>
          <button
            onClick={() => emit({ case: `suspendFilterClicked` })}
            className="flex-grow shadow-md transition duration-100 hover:bg-white/30 dark:hover:bg-white/10 px-4 py-3 space-x-5 bg-white/20 dark:bg-white/5 border-[0.5px] border-white/30 dark:border-white/20 rounded-xl w-1/2 flex justify-start items-center flex-row"
          >
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
                  props.recordingScreen
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
            {props.recordingScreen && (
              <p className="text-xs mt-0.5 text-center italic text-black/50 dark:text-white/50">
                Screen is being monitored
              </p>
            )}
          </div>
          <div className="flex flex-col justify-center items-center space-y-1 w-1/2">
            <button
              onClick={() => emit({ case: `refreshRulesClicked` })}
              className="flex items-center font-medium text-black/80 dark:text-white/80 transition duration-100 hover:bg-white/20 dark:hover:bg-white/10 hover:text-black dark:hover:text-white px-4 py-0.5 rounded-lg"
            >
              <ArrowRotateRight className="w-3.5 mr-2" />
              Refresh rules
            </button>
            <button
              onClick={() => emit({ case: `administrateClicked` })}
              className="flex items-center font-medium text-black/80 dark:text-white/80 transition duration-100 hover:bg-white/20 dark:hover:bg-white/10 hover:text-black dark:hover:text-white px-4 py-0.5 rounded-lg"
            >
              <Gear className="w-3.5 mr-2" />
              Administrate
            </button>
          </div>
        </div>
      </MenuBarSized>
    );
  }
  return (
    <MenuBarSized className="flex flex-col justify-center items-center">
      <p className="text-black/80 dark:text-white/70 font-medium">Welcome to</p>
      <Logo type="default" className="dark:[filter:brightness(600%)]" />
      <button
        onClick={() => emit({ case: `connectClicked` })}
        className="flex items-center text-lg font-bold bg-white/90 px-6 py-3 rounded-xl mt-8 shadow-md transition duration-100 hover:bg-white/100 hover:-translate-y-0.5 hover:shadow-lg active:translate-y-0 active:shadow"
      >
        <Laptop className="w-6 mr-3 text-indigo-600" />
        <span className="bg-gradient-to-br from-indigo-600 to-fuchsia-600 bg-clip-text text-transparent [-webkit-background-clip:text;]">
          Connect a device
        </span>
      </button>
    </MenuBarSized>
  );
};

// not sure why i have to specify the generics here... 🤔
export default containerize<AppState, AppEvent, ViewState, ViewAction>(store, MenuBar);

const MenuBarSized: React.FC<{ children: React.ReactNode; className?: string }> = ({
  children,
  className,
}) => <div className={cx(`w-[400px] h-[300px]`, className)}>{children}</div>;
