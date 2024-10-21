import React, { useState } from 'react';
import cx from 'classnames';
import type { AppEvent } from '../menubar-store';
import type { FilterState } from '../../lib/shared-types';
import { MenuBarSized } from '../MenuBar';

interface Props {
  emit(event: AppEvent): unknown;
  filterState: FilterState;
  recordingScreen: boolean;
  recordingKeystrokes: boolean;
  adminAttentionRequired: boolean;
  downtime?: { until: string };
}

const Connected: React.FC<Props> = ({
  emit,
  filterState,
  recordingKeystrokes,
  recordingScreen,
  adminAttentionRequired,
  downtime,
}) => {
  const [pauseMenuOpen, setPauseMenuOpen] = useState(false);

  return (
    <MenuBarSized className={cx(`select-none flex justify-center items-center relative`)}>
      {/* modal */}
      <div
        className={cx(
          `bg-white/50 dark:bg-white/10 backdrop-blur shadow-lg absolute z-20 px-3 py-2 rounded-xl w-80 transition-[opacity,transform] duration-300`,
          !pauseMenuOpen &&
            `pointer-events-none opacity-0 translate-y-32 scale-0 -translate-x-32`,
        )}
      >
        <header className="flex justify-between">
          <h2 className="font-medium text-lg dark:text-white">Choose a duration:</h2>
          <button className="cursor-default" onClick={() => setPauseMenuOpen(false)}>
            <i className="fa fa-times text-black/40 dark:text-white/70 text-sm bg-black/10 dark:bg-white/10 w-5 h-5 rounded-full flex justify-center items-center hover:bg-black/20 dark:hover:bg-white/20 hover:scale-110 active:bg-black/30 dark:active:bg-white/30 active:scale-95 transition-[background-color,transform] duration-200" />
          </button>
        </header>
        <div className="flex flex-wrap justify-center gap-2 py-4">
          <WhiteButton onClick={() => alert(`TODO`)}>10 minutes</WhiteButton>
          <WhiteButton onClick={() => alert(`TODO`)}>1 hour</WhiteButton>
          <WhiteButton onClick={() => alert(`TODO`)}>Until next downtime</WhiteButton>
        </div>
      </div>

      {/* overlay */}
      <div
        className={cx(
          `absolute w-full h-full top-0 left-0 z-10 transition-colors, duration-300`,
          pauseMenuOpen ? `bg-black/[15%]` : `bg-transparent pointer-events-none`,
        )}
        onClick={() => setPauseMenuOpen(false)}
      />

      {/* main ui */}
      <div
        className={cx(
          `flex flex-col relative p-3 flex-grow transition-[filter,transform,opacity] duration-300 self-stretch`,
          pauseMenuOpen && `blur scale-95 opacity-75`,
        )}
      >
        {downtime ? (
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
                Until {downtime.until}
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
                  <VioletButton onClick={() => emit({ case: `turnOnFilterClicked` })}>
                    Turn on
                  </VioletButton>
                )}
                {filterState.case === `suspended` && (
                  <VioletButton onClick={() => emit({ case: `resumeFilterClicked` })}>
                    Resume
                  </VioletButton>
                )}
                {filterState.case === `downtimePaused` && (
                  <VioletButton onClick={() => alert(`TODO: resume downtime`)}>
                    Resume
                  </VioletButton>
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
              <button
                onClick={() => emit({ case: `viewNetworkTrafficClicked` })}
                disabled={filterState.case === `off`}
                className={cx(
                  `flex-grow py-3 space-x-3.5 flex justify-center items-center flex-row bg-gradient-to-b from-white dark:from-black/50 to-white/20 dark:to-black dark:border-t dark:border-white/40 rounded-xl shadow dark:shadow-black/50 text-black/80 cursor-default hover:scale-[102%] active:scale-[98%] active:shadow hover:shadow-md transition-[transform,box-shadow] duration-100`,
                )}
              >
                <i className="fa fa-tower-broadcast text-lg shrink-0 text-black/70 dark:text-white/80" />
                <p className="font-medium text-left dark:text-white leading-tight">
                  Blocked requests
                </p>
              </button>
              <button
                onClick={() => emit({ case: `suspendFilterClicked` })}
                disabled={filterState.case === `off`}
                className={cx(
                  `flex-grow py-3 space-x-3.5 flex justify-center items-center flex-row bg-gradient-to-b from-white dark:from-black/50 to-white/20 dark:to-black dark:border-t dark:border-white/40 rounded-xl shadow dark:shadow-black/50 text-black/80 cursor-default hover:scale-[102%] active:scale-[98%] active:shadow hover:shadow-md transition-[transform,box-shadow] duration-100`,
                )}
              >
                <i className="fa fa-clock-rotate-left text-lg shrink-0 text-black/70 dark:text-white/80" />
                <p className="text-sm font-medium text-left leading-5 dark:text-white">
                  Suspend filter
                </p>
              </button>
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
            downtime ? `justify-between` : `flex-grow justify-end`,
          )}
        >
          {downtime && (
            <WhiteButton onClick={() => setPauseMenuOpen(true)} icon="fas fa-pause">
              Pause
            </WhiteButton>
          )}
          <div className="flex items-center space-x-2">
            <WhiteButton
              onClick={() => emit({ case: `refreshRulesClicked` })}
              icon="fa fa-arrows-rotate"
            />
            <WhiteButton
              onClick={() => emit({ case: `administrateClicked` })}
              icon="fa fa-cog"
              pinging={adminAttentionRequired}
            />
          </div>
        </div>
      </div>
    </MenuBarSized>
  );
};

export default Connected;

interface VioletButtonProps {
  onClick(): void;
  children: React.ReactNode;
}

const VioletButton: React.FC<VioletButtonProps> = ({ onClick, children }) => (
  <button
    onClick={onClick}
    className="bg-gradient-to-b from-violet-400 dark:from-violet-500 to-violet-500 dark:to-violet-700 px-2 py-1 rounded-lg text-white font-medium shadow border-t border-white/40 hover:scale-105 hover:shadow-md transition-[transform,box-shadow] duration-100 cursor-default active:scale-95"
  >
    {children}
  </button>
);

interface WhiteButtonProps {
  children?: React.ReactNode;
  icon?: string;
  onClick(): void;
  pinging?: boolean;
}

const WhiteButton: React.FC<WhiteButtonProps> = ({
  children,
  icon,
  onClick,
  pinging,
}) => (
  <button
    onClick={onClick}
    className={cx(
      `group bg-gradient-to-b from-white dark:from-black/50 to-white/70 dark:to-black font-medium rounded-xl group transition-[background-color,transform] active:bg-white/60 duration-100 shadow active:scale-95 cursor-default dark:text-white dark:shadow-black/50 dark:border-t dark:border-white/40 flex justify-center items-center relative`,
      children && `px-4 py-1`,
      icon && !children && `w-8 h-8`,
    )}
  >
    {pinging && (
      <>
        <div className="absolute w-2 h-2 bg-red-400 top-0 right-0 rounded-full" />
        <div className="absolute w-3 h-3 bg-red-400 -top-0.5 -right-0.5 rounded-full animate-ping" />
      </>
    )}
    <span
      className={cx(
        `transition-transform duration-200 flex space-x-2 items-center`,
        children && `group-hover:scale-105`,
        icon && !children && `group-hover:scale-110`,
      )}
    >
      {icon && <i className={icon} />}
      {children && <span>{children}</span>}
    </span>
  </button>
);
