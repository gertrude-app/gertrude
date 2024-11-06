import React from 'react';
import cx from 'classnames';
import { ArrowsRightLeftIcon } from '@heroicons/react/24/outline';
import type { KeychainSchedule } from '@dash/types';

const SpecifyingActiveOrInactive: React.FC<{
  schedule: KeychainSchedule;
  setSchedule(schedule: KeychainSchedule): void;
  isTouchDevice: boolean;
}> = ({ schedule, setSchedule, isTouchDevice }) => (
  <button
    className={cx(
      `capitalize font-medium flex items-center group py-0.5 rounded-lg active:scale-90 active:bg-slate-300 transition-[transform,background-color,margin,padding] duration-200`,
      isTouchDevice
        ? `bg-slate-200/60 px-2`
        : `bg-slate-200/60 hover:bg-slate-200 px-2 min-[672px]:px-[3px] min-[672px]:bg-transparent min-[672px]:hover:bg-slate-200 min-[672px]:hover:px-2`,
    )}
    onClick={() =>
      setSchedule({
        ...schedule,
        mode: schedule.mode === `active` ? `inactive` : `active`,
      })
    }
  >
    <span className="text-slate-700">{schedule.mode}</span>
    <ArrowsRightLeftIcon
      className={cx(
        `shrink-0 transition-[width,margin-left,filter] text-slate-400 duration-200`,
        isTouchDevice
          ? `w-4 ml-2`
          : `w-4 ml-2 min-[672px]:w-0 min-[672px]:ml-0 min-[672px]:group-hover:w-4 min-[672px]:group-hover:ml-2`,
      )}
      strokeWidth={2.5}
    />
  </button>
);

export default SpecifyingActiveOrInactive;
