import cx from 'classnames';
import React from 'react';
import type { RuleSchedule } from '@dash/types';
import TimeInput from '../../Forms/TimeInput';
import DropdownCustomizationPoint from './DropdownCustomizationPoint';

const WhatTime: React.FC<{
  schedule: RuleSchedule;
  setSchedule(schedule: RuleSchedule): void;
  isTouchDevice: boolean;
}> = ({ schedule, setSchedule, isTouchDevice }) => {
  const isInvalid = (() => {
    switch (true) {
      case schedule.window.start.hour > schedule.window.end.hour:
      case schedule.window.start.hour === schedule.window.end.hour &&
        schedule.window.start.minute >= schedule.window.end.minute:
        return true;
      default:
        return false;
    }
  })();

  return (
    <DropdownCustomizationPoint
      isTouchDevice={isTouchDevice}
      text={
        <span className={cx(isInvalid && `!text-red-600`)}>
          {schedule.window.start.hour === 0 &&
          schedule.window.start.minute === 0 &&
          schedule.window.end.hour === 23 &&
          schedule.window.end.minute === 59
            ? `all day
          long`
            : `${formatTime(schedule.window.start.hour, schedule.window.start.minute)} to
          ${formatTime(schedule.window.end.hour, schedule.window.end.minute)}`}
        </span>
      }
    >
      <div className="flex flex-col gap-4">
        <div className="flex flex-col gap-1.5">
          <span className="text-xs text-slate-500">Start:</span>
          <TimeInput
            time={schedule.window.start}
            setTime={(time) =>
              setSchedule({
                ...schedule,
                window: {
                  ...schedule.window,
                  start: time,
                },
              })
            }
          />
        </div>
        <div className="flex flex-col gap-1.5">
          <span className="text-xs text-slate-500">End:</span>
          <TimeInput
            time={schedule.window.end}
            setTime={(time) =>
              setSchedule({ ...schedule, window: { ...schedule.window, end: time } })
            }
          />
        </div>
      </div>
      <div
        className={cx(
          `w-[162px] bg-red-50 rounded-lg text-red-500 text-sm self-center text-center font-medium leading-tight overflow-hidden transition-[opacity,padding,height,margin] duration-200`,
          isInvalid ? `p-2 h-[52px] mt-6` : `h-0 p-0 mt-0 opacity-0`,
        )}
      >
        End time must be after start time
      </div>
    </DropdownCustomizationPoint>
  );
};

export default WhatTime;

function formatTime(hour: number, minute: number): string {
  const pm = hour >= 12;
  const h = hour % 12 || 12;
  return `${h}:${minute.toString().padStart(2, `0`)} ${pm ? `PM` : `AM`}`;
}
