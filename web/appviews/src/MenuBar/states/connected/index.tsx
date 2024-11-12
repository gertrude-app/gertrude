import React from 'react';
import cx from 'classnames';
import type { AppEvent, ViewAction } from '../../menubar-store';
import type { FilterState } from '../../../lib/shared-types';
import { MenuBarSized } from '../../MenuBar';
import * as Btn from './Buttons';
import PauseDowntimeModal from './PauseDowntimeModal';

interface Props {
  emit(event: AppEvent): unknown;
  dispatch(action: ViewAction): unknown;
  filterState: FilterState;
  recordingScreen: boolean;
  recordingKeystrokes: boolean;
  adminAttentionRequired: boolean;
  showingDowntimePauseDuration: boolean;
}

const Connected: React.FC<Props> = ({
  emit,
  dispatch,
  filterState,
  recordingKeystrokes,
  recordingScreen,
  adminAttentionRequired,
  showingDowntimePauseDuration,
}) => (
  <MenuBarSized className={cx(`select-none flex justify-center items-center relative`)}>
    <PauseDowntimeModal
      open={showingDowntimePauseDuration}
      emit={emit}
      dispatch={dispatch}
    />

    <div
      className={cx(
        `flex flex-col relative p-3 flex-grow transition-[filter,transform,opacity] duration-300 self-stretch`,
        showingDowntimePauseDuration && `blur scale-95 opacity-75`,
      )}
    >
      {filterState.case === `downtime` ? (
        <div className="flex justify-center items-center flex-grow">
          <div
            className={cx(
              `w-[800px] h-128 absolute -left-[200px] -bottom-64 [background:radial-gradient(#8b5cf650_0%,transparent_70%)]`,
            )}
          />
          <div className="flex justify-center items-center flex-col">
            <span className="text-3xl font-semibold text-black/60 dark:text-white/70">
              In downtime
            </span>
            <span className="font-medium text-black/50 dark:text-white/60">
              Until {filterState.ending}
            </span>
          </div>
        </div>
      ) : (
        <>
          <div
            className={cx(`w-[800px] h-80 absolute -left-[400px] -top-40`, {
              '[background:radial-gradient(#4ade8050_0%,transparent_70%)] dark:[background:radial-gradient(#22c55e40_0%,transparent_70%)]':
                filterState.case === `on`,
              '[background:radial-gradient(#f8717150_0%,transparent_70%)] dark:[background:radial-gradient(#ef444440_0%,transparent_70%)]':
                filterState.case === `off`,
              '[background:radial-gradient(#facc1550_0%,transparent_70%)] dark:[background:radial-gradient(#eab30840_0%,transparent_70%)]':
                filterState.case === `suspended`,
              '[background:radial-gradient(#e879f950_0%,transparent_70%)] dark:[background:radial-gradient(#d946ef40_0%,transparent_70%)]':
                filterState.case === `downtimePaused`,
            })}
          />
          <div className="relative">
            <div className="flex justify-between items-center">
              <span
                className={cx(`px-2 py-1 rounded-lg font-medium`, {
                  'bg-green-400/50 text-green-950 dark:text-green-50':
                    filterState.case === `on`,
                  'bg-red-400/50 text-red-950 dark:text-red-50':
                    filterState.case === `off`,
                  'bg-yellow-400/50 text-yellow-950 dark:text-yellow-50':
                    filterState.case === `suspended`,
                  'bg-fuchsia-400/50 text-fuchsia-950 dark:text-fuchsia-50':
                    filterState.case === `downtimePaused`,
                })}
              >
                {filterState.case === `downtimePaused`
                  ? `Downtime paused`
                  : `Filter ${filterState.case}`}
              </span>
              {filterState.case === `off` && (
                <Btn.Violet onClick={() => emit({ case: `turnOnFilterClicked` })}>
                  Turn on
                </Btn.Violet>
              )}
              {filterState.case === `suspended` && (
                <Btn.Violet onClick={() => emit({ case: `resumeFilterClicked` })}>
                  Resume
                </Btn.Violet>
              )}
              {filterState.case === `downtimePaused` && (
                <Btn.Violet onClick={() => emit({ case: `resumeDowntimeClicked` })}>
                  Resume
                </Btn.Violet>
              )}
            </div>
            {(filterState.case === `suspended` ||
              filterState.case === `downtimePaused`) && (
              <p className="mt-1 text-sm text-black/60 dark:text-white/80">
                Resuming {filterState.resuming}
              </p>
            )}
          </div>
          <div className="flex mt-3 space-x-3 relative">
            <Btn.Labeled
              onClick={() => emit({ case: `viewNetworkTrafficClicked` })}
              disabled={filterState.case === `off` || filterState.case === `suspended`}
              iconClass="fa-tower-broadcast"
            >
              Blocked requests
            </Btn.Labeled>
            <Btn.Labeled
              onClick={() => emit({ case: `suspendFilterClicked` })}
              disabled={filterState.case === `off` || filterState.case === `suspended`}
              iconClass="fa-clock-rotate-left"
            >
              Suspend filter
            </Btn.Labeled>
          </div>
          <div className="mt-3 flex flex-col space-y-3 bg-white/20 dark:bg-black/20 p-3 rounded-xl">
            <div className="flex items-center space-x-3">
              <div
                className={cx(
                  `w-7 h-7 rounded-full flex items-center justify-center text-white dark:shadow-black/30`,
                  recordingScreen
                    ? `bg-violet-500 dark:bg-violet-200 dark:text-violet-700 shadow-md`
                    : `bg-black/10 dark:bg-white/10`,
                )}
              >
                <i className="fa-solid fa-binoculars text-sm" />
              </div>
              <span
                className={cx(
                  `font-medium`,
                  recordingScreen
                    ? `bg-gradient-to-r from-violet-700 dark:from-violet-300 to-black/70 dark:to-white/70 bg-clip-text text-transparent`
                    : `text-black/40 dark:text-white/40`,
                )}
              >
                {recordingScreen
                  ? `Screen is being recorded`
                  : `Screen is not being recorded`}
              </span>
            </div>
            <div className="flex items-center space-x-3">
              <div
                className={cx(
                  `w-7 h-7 rounded-full flex items-center justify-center text-white dark:shadow-black/30`,
                  recordingKeystrokes
                    ? `bg-violet-500 dark:bg-violet-200 dark:text-violet-700 shadow-md`
                    : `bg-black/10 dark:bg-white/10`,
                )}
              >
                <i className="fa-solid fa-keyboard text-sm" />
              </div>
              <span
                className={cx(
                  `font-medium`,
                  recordingKeystrokes
                    ? `bg-gradient-to-r from-violet-700 dark:from-violet-300 to-black/70 dark:to-white/70 bg-clip-text text-transparent`
                    : `text-black/40 dark:text-white/40`,
                )}
              >
                {recordingKeystrokes
                  ? `Keystrokes are being recorded`
                  : `Keystrokes are not being recorded`}
              </span>
            </div>
          </div>
        </>
      )}
      <div
        className={cx(
          `flex items-end relative`,
          filterState.case === `downtime` ? `justify-between` : `flex-grow justify-end`,
        )}
      >
        {filterState.case === `downtime` && (
          <Btn.White
            onClick={() => dispatch({ type: `toggleShowingDowntimePauseDuration` })}
            icon="fas fa-pause"
          >
            Pause
          </Btn.White>
        )}
        <div className="flex items-center space-x-2">
          <Btn.White
            onClick={() => emit({ case: `refreshRulesClicked` })}
            icon="fa fa-arrows-rotate"
          />
          <Btn.White
            onClick={() => emit({ case: `administrateClicked` })}
            icon="fa fa-cog"
            pinging={adminAttentionRequired}
          />
        </div>
      </div>
    </div>
  </MenuBarSized>
);

export default Connected;
