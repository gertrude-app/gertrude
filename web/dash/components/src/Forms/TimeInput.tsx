'use client';

import React, { useEffect, useState } from 'react';
import cx from 'classnames';
import { ChevronDownIcon, ChevronUpIcon } from '@heroicons/react/24/outline';
import type { PlainTime } from '@dash/types';

interface Props {
  time: PlainTime;
  setTime(time: PlainTime): void;
}

const TimeInput: React.FC<Props> = ({ time, setTime }) => (
  <div className="flex items-center gap-0.5">
    <NumberChanger
      type="hour"
      value={time.hour > 12 ? time.hour - 12 : time.hour || 12}
      setValue={(value) => {
        setTime({
          ...time,
          hour:
            time.hour >= 12 ? (value > 11 ? 23 : value + 12) : value > 23 ? 23 : value,
        });
      }}
      onIncrement={() => {
        const hour = time.hour;
        setTime({
          ...time,
          hour: hour === 23 ? 0 : hour + 1,
        });
      }}
      onDecrement={() => {
        const hour = time.hour;
        setTime({
          ...time,
          hour: hour === 0 ? 23 : hour - 1,
        });
      }}
    />
    <span className="text-xl font-medium font-mono">:</span>
    <NumberChanger
      type="minute"
      value={time.minute}
      setValue={(value) => {
        setTime({
          ...time,
          minute: value > 59 ? 59 : value,
        });
      }}
      onIncrement={() => {
        const minute = time.minute;
        if (minute === 59) {
          setTime({
            hour: time.hour === 23 ? 0 : time.hour + 1,
            minute: 0,
          });
        } else {
          setTime({
            ...time,
            minute: minute + 1,
          });
        }
      }}
      onDecrement={() => {
        const minute = time.minute;
        if (minute === 0) {
          setTime({
            hour: time.hour === 0 ? 23 : time.hour - 1,
            minute: 59,
          });
        } else {
          setTime({
            ...time,
            minute: minute - 1,
          });
        }
      }}
    />
    <AmPmToggle
      value={time.hour >= 12 ? `pm` : `am`}
      onClick={() => {
        const hour = time.hour;
        setTime({
          ...time,
          hour: hour >= 12 ? hour - 12 : hour + 12,
        });
      }}
    />
  </div>
);

export default TimeInput;

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
    <div className={cx(`flex gap-1`, type === `minute` && `flex-row-reverse`)}>
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
        pattern="[0-9]*"
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
    className="rounded-full hover:scale-110 hover:bg-slate-200 w-6 h-6 bg-slate-100 flex justify-center items-center ml-2 transition-[background-color,transform] active:scale-90 active:bg-slate-300 duration-200"
  >
    <span className="font-semibold text-slate-500 text-[10px] uppercase">{value}</span>
  </button>
);

function padded(num: number): string {
  return num.toString().padStart(2, `0`);
}
