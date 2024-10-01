import React, { useEffect, useState } from 'react';
import cx from 'classnames';
import { ChevronDownIcon, ChevronUpIcon } from '@heroicons/react/24/outline';
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
        <TimeSetter type="start" schedule={schedule} setSchedule={setSchedule} />
        <TimeSetter type="end" schedule={schedule} setSchedule={setSchedule} />
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

interface TimeSetterProps {
  type: `start` | `end`;
  schedule: Schedule;
  setSchedule(schedule: Schedule): void;
}

const TimeSetter: React.FC<TimeSetterProps> = ({ type, schedule, setSchedule }) => (
  <div>
    <span className="text-xs text-slate-500 capitalize">{type}:</span>
    <div className="flex items-center gap-0.5">
      <NumberChanger
        type="hour"
        value={
          schedule.time[type].hour > 12
            ? schedule.time[type].hour - 12
            : schedule.time[type].hour || 12
        }
        setValue={(value) => {
          setSchedule({
            ...schedule,
            time: {
              ...schedule.time,
              [type]: {
                ...schedule.time[type],
                hour:
                  schedule.time[type].hour >= 12
                    ? value > 11
                      ? 23
                      : value + 12
                    : value > 23
                      ? 23
                      : value,
              },
            },
          });
        }}
        onIncrement={() => {
          const hour = schedule.time[type].hour;
          setSchedule({
            ...schedule,
            time: {
              ...schedule.time,
              [type]: {
                ...schedule.time[type],
                hour: hour === 23 ? 0 : hour + 1,
              },
            },
          });
        }}
        onDecrement={() => {
          const hour = schedule.time[type].hour;
          setSchedule({
            ...schedule,
            time: {
              ...schedule.time,
              [type]: {
                ...schedule.time[type],
                hour: hour === 0 ? 23 : hour - 1,
              },
            },
          });
        }}
      />
      <span className="text-xl font-medium font-mono -mb-1.5">:</span>
      <NumberChanger
        type="minute"
        value={schedule.time[type].minute}
        setValue={(value) => {
          setSchedule({
            ...schedule,
            time: {
              ...schedule.time,
              [type]: {
                ...schedule.time[type],
                minute: value > 59 ? 59 : value,
              },
            },
          });
        }}
        onIncrement={() => {
          const minute = schedule.time[type].minute;
          if (minute === 59) {
            setSchedule({
              ...schedule,
              time: {
                ...schedule.time,
                [type]: {
                  hour:
                    schedule.time[type].hour === 23 ? 0 : schedule.time[type].hour + 1,
                  minute: 0,
                },
              },
            });
          } else {
            setSchedule({
              ...schedule,
              time: {
                ...schedule.time,
                [type]: {
                  ...schedule.time[type],
                  minute: minute + 1,
                },
              },
            });
          }
        }}
        onDecrement={() => {
          const minute = schedule.time[type].minute;
          if (minute === 0) {
            setSchedule({
              ...schedule,
              time: {
                ...schedule.time,
                [type]: {
                  hour:
                    schedule.time[type].hour === 0 ? 23 : schedule.time[type].hour - 1,
                  minute: 59,
                },
              },
            });
          } else {
            setSchedule({
              ...schedule,
              time: {
                ...schedule.time,
                [type]: {
                  ...schedule.time[type],
                  minute: minute - 1,
                },
              },
            });
          }
        }}
      />
      <AmPmToggle
        value={schedule.time[type].hour >= 12 ? `pm` : `am`}
        onClick={() => {
          const hour = schedule.time[type].hour;
          setSchedule({
            ...schedule,
            time: {
              ...schedule.time,
              [type]: {
                ...schedule.time[type],
                hour: hour >= 12 ? hour - 12 : hour + 12,
              },
            },
          });
        }}
      />
    </div>
  </div>
);

interface NumberChangerProps {
  type: `hour` | `minute`;
  value: number;
  setValue(value: number): void;
  onIncrement(): void;
  onDecrement(): void;
}

const NumberChanger: React.FC<NumberChangerProps> = ({
  type,
  value,
  setValue,
  onIncrement,
  onDecrement,
}) => {
  const [inputValue, setInputValue] = useState(String(value));

  useEffect(() => {
    setInputValue(type === `hour` ? String(value) : padded(value));
  }, [value, type]);

  return (
    <div className={cx(`flex mt-2 gap-1`, type === `minute` && `flex-row-reverse`)}>
      <div className="flex flex-col shrink-0 gap-1">
        <button
          onClick={onIncrement}
          className="rounded-full w-4 h-4 bg-slate-200 flex justify-center items-center text-slate-500 hover:scale-125 hover:bg-slate-300 active:bg-violet-300 active:text-violet-600 active:scale-90 transition-[background-color,text-color,transform] duration-200"
        >
          <ChevronUpIcon className="w-3" strokeWidth={3} />
        </button>
        <button
          onClick={onDecrement}
          className="rounded-full w-4 h-4 bg-slate-200 flex justify-center items-center text-slate-500 hover:scale-125 hover:bg-slate-300 active:bg-violet-300 active:text-violet-600 active:scale-90 transition-[background-color,text-color,transform] duration-200"
        >
          <ChevronDownIcon className="w-3" strokeWidth={3} />
        </button>
      </div>
      <input
        className={cx(
          `bg-slate-100 rounded w-9 font-mono font-medium text-slate-800 px-1 pt-[3px] text-xl focus:bg-slate-200 outline-none border-b-2 border-b-transparent focus:border-b-violet-400 focus:rounded-b-none transition-[background-color,border-color,border-radius] duration-200`,
          type === `hour` && `text-right`,
        )}
        value={inputValue}
        onChange={(e) => {
          setInputValue(e.target.value);
        }}
        onBlur={() => {
          const numericValue = Number(inputValue);
          if (isNaN(numericValue) || numericValue < 0) {
            if (type === `minute`) {
              setInputValue(padded(value));
            } else {
              setInputValue(String(value));
            }
          } else if (type === `hour`) {
            setValue(numericValue);
            setInputValue(String(numericValue));
          } else if (type === `minute`) {
            setValue(numericValue);
            setInputValue(padded(numericValue));
          }
        }}
      />
    </div>
  );
};

interface AmPmToggleProps {
  value: `am` | `pm`;
  onClick(): void;
}

const AmPmToggle: React.FC<AmPmToggleProps> = ({ value, onClick }) => (
  <button
    onClick={onClick}
    className="rounded-full hover:scale-110 hover:bg-slate-200 w-6 h-6 bg-slate-100 flex justify-center items-center ml-2 -mb-1.5 transition-[background-color,transform] active:scale-90 active:bg-slate-300 duration-200"
  >
    <span className="font-semibold text-slate-500 text-[10px] uppercase">{value}</span>
  </button>
);

// helpers

function formatTime(hour: number, minute: number): string {
  const pm = hour >= 12;
  const h = hour % 12 || 12;
  return `${h}:${minute.toString().padStart(2, `0`)} ${pm ? `PM` : `AM`}`;
}

function padded(num: number): string {
  return num.toString().padStart(2, `0`);
}
