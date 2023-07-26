import React from 'react';
import cx from 'classnames';
import type { AppEvent } from '../menubar-store';
import type { FilterState } from '../../lib/shared-types';
import { MenuBarSized } from '../MenuBar';
import FilterBadge, { FilterStateBadge } from '../FilterBadge';

interface Props {
  emit(event: AppEvent): unknown;
  filterState: FilterState;
  recordingScreen: boolean;
  recordingKeystrokes: boolean;
  adminAttentionRequired: boolean;
}

const Connected: React.FC<Props> = ({
  emit,
  filterState,
  recordingKeystrokes,
  recordingScreen,
  adminAttentionRequired,
}) => (
  <MenuBarSized className="p-3 select-none flex flex-col">
    <div className="bg-white/20 dark:bg-white/5 shadow-md px-3 py-2 rounded-xl border-[0.5px] border-white/30 dark:border-white/20">
      <div className="flex items-center space-x-1.5">
        <h3 className="text-black dark:text-white font-medium grow">Internet filter</h3>
        {filterState.case === `off` && (
          <FilterBadge color="grey" onClick={() => emit({ case: `turnOnFilterClicked` })}>
            Turn on
          </FilterBadge>
        )}
        {filterState.case === `suspended` && (
          <FilterBadge color="grey" onClick={() => emit({ case: `resumeFilterClicked` })}>
            Resume
          </FilterBadge>
        )}
        <FilterStateBadge state={filterState.case} />
      </div>
      {filterState.case === `suspended` && (
        <p className="mt-1 italic text-sm text-black/70 dark:text-white/70">
          Resuming {filterState.resuming}
        </p>
      )}
    </div>
    <div className="flex mt-3 space-x-3">
      <button
        onClick={() => emit({ case: `viewNetworkTrafficClicked` })}
        className="flex-grow shadow-md transition duration-100 hover:bg-white/30 dark:hover:bg-white/10 px-4 py-3 space-x-5 bg-white/20 dark:bg-white/5 border-[0.5px] border-white/30 dark:border-white/20 rounded-xl w-1/2 flex justify-start items-center flex-row"
      >
        <i className="fa fa-tower-broadcast text-xl w-6 shrink-0 text-black/70 dark:text-white/80" />
        <p className="text-sm font-medium text-left dark:text-white leading-tight">
          View network requests
        </p>
      </button>
      <button
        onClick={() => emit({ case: `suspendFilterClicked` })}
        className="flex-grow shadow-md transition duration-100 hover:bg-white/30 dark:hover:bg-white/10 px-4 py-3 space-x-5 bg-white/20 dark:bg-white/5 border-[0.5px] border-white/30 dark:border-white/20 rounded-xl w-1/2 flex justify-start items-center flex-row"
      >
        <i className="fa fa-clock-rotate-left text-xl *h-5 shrink-0 text-black/70 dark:text-white/80" />
        <p className="text-sm font-medium text-left leading-5 dark:text-white">
          Suspend filter
        </p>
      </button>
    </div>
    <div className="flex justify-between flex-grow mt-3 space-x-3">
      <div className="flex flex-col justify-center items-center bg-white/20 dark:bg-white/5 p-3 rounded-xl shadow-md border-[0.5px] border-white/30 dark:border-white/20 w-1/2">
        <div className="flex justify-center items-center space-x-3 mb-1">
          <div
            className={cx(
              `rounded-full w-10 h-10 flex justify-center items-center`,
              recordingScreen
                ? `bg-indigo-300/40 dark:bg-indigo-600/50 text-indigo-600 dark:text-indigo-300`
                : `bg-black/5 dark:bg-white/5 text-black/30 dark:text-white/30`,
            )}
          >
            <i className="fa fa-binoculars text-xl w-5" />
          </div>
          <div
            className={cx(
              `rounded-full w-10 h-10 flex justify-center items-center`,
              recordingKeystrokes
                ? `bg-indigo-300/40 dark:bg-indigo-600/50 text-indigo-600 dark:text-indigo-300`
                : `bg-black/5 dark:bg-white/5 text-black/30 dark:text-white/30`,
            )}
          >
            <i className="fa fa-keyboard text-xl w-5" />
          </div>
        </div>
        {recordingKeystrokes && (
          <p className="text-xs mt-0.5 text-center italic text-black/50 dark:text-white/50">
            Keystrokes are being monitored
          </p>
        )}
        {recordingScreen && (
          <p className="text-xs mt-0.5 text-center italic text-black/50 dark:text-white/50">
            Screen is being monitored
          </p>
        )}
      </div>
      <div className="flex flex-col justify-center items-center space-y-1 w-1/2">
        <button
          onClick={() => emit({ case: `refreshRulesClicked` })}
          className="flex items-center font-medium text-black/80 dark:text-white/80 transition duration-100 hover:bg-white/20 dark:hover:bg-white/10 hover:text-black dark:hover:text-white px-5 py-0.5 rounded-lg"
        >
          <i className="fa fa-arrow-rotate-right text-sm w-3.5 mr-2" />
          Refresh rules
        </button>
        <button
          onClick={() => emit({ case: `administrateClicked` })}
          className="relative flex items-center font-medium text-black/80 dark:text-white/80 transition duration-100 hover:bg-white/20 dark:hover:bg-white/10 hover:text-black dark:hover:text-white px-5 py-0.5 rounded-lg"
        >
          {adminAttentionRequired && (
            <>
              <div className="absolute w-2 h-2 bg-red-400 rounded-full top-1 right-1.5" />
              <div className="absolute w-2 h-2 bg-red-400 rounded-full top-1 right-1.5 animate-ping" />
            </>
          )}
          <i className="fa fa-gear text-sm w-3.5 mr-2" />
          Administrate
        </button>
      </div>
    </div>
  </MenuBarSized>
);

export default Connected;
