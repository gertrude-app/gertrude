import React from 'react';
import cx from 'classnames';
import { ArrowsRightLeftIcon } from '@heroicons/react/24/outline';
import type { RuleSchedule } from '@dash/types';

const SpecifyingActiveOrInactive: React.FC<{
  schedule: RuleSchedule;
  setSchedule(schedule: RuleSchedule): void;
  isTouchDevice: boolean;
  text?: Record<RuleSchedule[`mode`], string>;
}> = ({ schedule, setSchedule, isTouchDevice, text = {} }) => (
  <button
    className={cx(
      `capitalize font-medium flex items-center group py-0.5 rounded-lg active:scale-90 active:bg-slate-300 transition-[transform,background-color,margin,padding] duration-200`,
      isTouchDevice
        ? `bg-slate-200/60 px-2`
        : `bg-slate-200/60 hover:bg-slate-200 px-2 @[672px]/schedule:px-[3px] @[672px]/schedule:bg-transparent @[672px]/schedule:hover:bg-slate-200 @[672px]/schedule:hover:px-2`,
    )}
    onClick={() =>
      setSchedule({
        ...schedule,
        mode: schedule.mode === `active` ? `inactive` : `active`,
      })
    }
  >
    <span className="text-slate-700">{text[schedule.mode] ?? schedule.mode}</span>
    <ArrowsRightLeftIcon
      className={cx(
        `shrink-0 transition-[width,margin-left,filter] text-slate-400 duration-200`,
        isTouchDevice
          ? `w-4 ml-2`
          : `w-4 ml-2 @[672px]/schedule:w-0 @[672px]/schedule:ml-0 @[672px]/schedule:group-hover:w-4 @[672px]/schedule:group-hover:ml-2`,
      )}
      strokeWidth={2.5}
    />
  </button>
);

export default SpecifyingActiveOrInactive;
