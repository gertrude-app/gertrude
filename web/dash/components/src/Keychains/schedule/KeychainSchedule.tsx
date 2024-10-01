import React from 'react';
import cx from 'classnames';
import SpecifyingAllowedOrBlocked from './SpecifyingAllowedOrBlocked';
import WhatDays from './WhatDays';
import WhatTime from './WhatTime';

export type Schedule = {
  specifyingWhen: 'active' | 'inactive';
  days: {
    sunday: boolean;
    monday: boolean;
    tuesday: boolean;
    wednesday: boolean;
    thursday: boolean;
    friday: boolean;
    saturday: boolean;
  };
  time: {
    start: {
      hour: number;
      minute: number;
    };
    end: {
      hour: number;
      minute: number;
    };
  };
};

interface Props {
  schedule: Schedule;
  setSchedule(schedule: Schedule): void;
}

const KeychainSchedule: React.FC<Props> = ({ schedule, setSchedule }) => (
  <div
    className={cx(
      `flex justify-center self-center py-1 px-2 items-center rounded-lg transition-colors duration-200 flex-wrap text-sm md:text-base`,
      isTouchDevice()
        ? `bg-transparent gap-1`
        : `bg-transparent gap-1 min-[672px]:gap-0 min-[672px]:bg-slate-200/50 min-[672px]:hover:bg-transparent`,
    )}
  >
    <SpecifyingAllowedOrBlocked
      schedule={schedule}
      setSchedule={setSchedule}
      isTouchDevice={isTouchDevice()}
    />
    <span className="text-slate-600 px-[3px]">on</span>
    <WhatDays
      schedule={schedule}
      setSchedule={setSchedule}
      isTouchDevice={isTouchDevice()}
    />
    {(schedule.time.start.hour !== 0 ||
      schedule.time.start.minute !== 0 ||
      schedule.time.end.hour !== 23 ||
      schedule.time.end.minute !== 59) && (
      <span className="text-slate-600 px-[3px]">from</span>
    )}
    <WhatTime
      schedule={schedule}
      setSchedule={setSchedule}
      isTouchDevice={isTouchDevice()}
    />
  </div>
);

export default KeychainSchedule;

function isTouchDevice(): boolean {
  return (
    `ontouchstart` in window ||
    navigator.maxTouchPoints > 0 ||
    navigator.maxTouchPoints > 0
  );
}
