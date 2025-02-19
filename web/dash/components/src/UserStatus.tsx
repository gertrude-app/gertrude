import React from 'react';
import cx from 'classnames';
import { relativeTime } from '@dash/datetime';
import type { ChildComputerStatus } from '@dash/types';

interface Props {
  name?: string;
  status: ChildComputerStatus;
}

const UserStatus: React.FC<Props> = ({ status, name }) => {
  const description: {
    color: string;
    gradient?: string;
    primaryText: string;
    secondaryText?: string;
  } = (() => {
    switch (status.case) {
      case `filterSuspended`:
        return {
          color: `bg-yellow-500`,
          gradient: `[background:radial-gradient(#eab30820_0%,transparent_70%)]`,
          primaryText: `Filter suspended`,
          secondaryText: status.resuming && `Resuming ${relativeTime(status.resuming)}`,
        };
      case `downtime`:
        return {
          color: `bg-purple-500`,
          gradient: `[background:radial-gradient(#a855f720_0%,transparent_70%)]`,
          primaryText: `In downtime`,
          secondaryText: status.ending && `Ending ${relativeTime(status.ending)}`,
        };
      case `downtimePaused`:
        return {
          color: `bg-yellow-500`,
          gradient: `[background:radial-gradient(#eab30820_0%,transparent_70%)]`,
          primaryText: `Downtime paused`,
          secondaryText: status.resuming && `Resuming ${relativeTime(status.resuming)}`,
        };
      case `offline`:
        return {
          color: `bg-slate-200`,
          primaryText: `Offline`,
        };
      case `filterOff`:
        return {
          color: `bg-red-500`,
          gradient: `[background:radial-gradient(#ef444420_0%,transparent_70%)]`,
          primaryText: `Filter off`,
        };
      case `filterOn`:
        return {
          color: `bg-green-500`,
          gradient: `[background:radial-gradient(#22c55e20_0%,transparent_70%)]`,
          primaryText: `Filter on`,
        };
    }
  })();

  return (
    <div
      className={cx(
        `border-[0.5px] border-slate-300 relative overflow-hidden bg-gradient-to-b from-white to-slate-50/50 shadow shadow-slate-300/30`,
        name
          ? `px-4 py-2 rounded-2xl`
          : `px-2 @sm:px-3 py-1.5 @sm:py-2 rounded-xl @sm:rounded-2xl`,
      )}
    >
      <div
        className={cx(
          `w-[600px] h-40 absolute -left-[300px] -bottom-20`,
          description.gradient,
        )}
      />
      {name && <h3 className="text-lg font-semibold">{name}</h3>}
      <div
        className={cx(
          `flex`,
          name ? `items-start gap-2` : `items-center gap-2 @sm:gap-3`,
        )}
      >
        <div
          className={cx(
            `w-2 h-2 rounded-full shrink-0`,
            description.color,
            name && `mt-1.5`,
          )}
        />
        <div className="flex flex-col">
          <span className="font-medium text-black/60 text-xs @sm:text-sm shrink-0 whitespace-nowrap">
            {description.primaryText}
          </span>
          {description.secondaryText && (
            <span className="text-[11px] @sm:text-xs text-black/40 leading-[1]">
              {description.secondaryText}
            </span>
          )}
        </div>
      </div>
    </div>
  );
};

export default UserStatus;
