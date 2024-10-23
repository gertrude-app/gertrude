import React from 'react';
import cx from 'classnames';
import { TimeInput } from '@shared/components';
import type { Schedule } from './KeychainSchedule';
import DropdownCustomizationPoint from './DropdownCustomizationPoint';

const WhatTime: React.FC<{
  schedule: Schedule;
  setSchedule(schedule: Schedule): void;
  isTouchDevice: boolean;
}> = ({ schedule, setSchedule, isTouchDevice }) => {
  const isInvalid = (() => {
    switch (true) {
      case schedule.time.start.hour > schedule.time.end.hour:
      case schedule.time.start.hour === schedule.time.end.hour &&
        schedule.time.start.minute >= schedule.time.end.minute:
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
          {schedule.time.start.hour === 0 &&
          schedule.time.start.minute === 0 &&
          schedule.time.end.hour === 23 &&
          schedule.time.end.minute === 59
            ? `all day
          long`
            : `${formatTime(schedule.time.start.hour, schedule.time.start.minute)} to
          ${formatTime(schedule.time.end.hour, schedule.time.end.minute)}`}
        </span>
      }
    >
      <div className="flex flex-col gap-4">
        <div className="flex flex-col gap-1.5">
          <span className="text-xs text-slate-500">Start:</span>
          <TimeInput
            time={schedule.time.start}
            setTime={(time) =>
              setSchedule({
                ...schedule,
                time: {
                  ...schedule.time,
                  start: time,
                },
              })
            }
          />
        </div>
        <div className="flex flex-col gap-1.5">
          <span className="text-xs text-slate-500">End:</span>
          <TimeInput
            time={schedule.time.end}
            setTime={(time) =>
              setSchedule({ ...schedule, time: { ...schedule.time, end: time } })
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
