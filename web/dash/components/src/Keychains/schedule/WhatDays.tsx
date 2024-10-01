import React from 'react';
import cx from 'classnames';
import { typesafe } from '@shared/ts-utils';
import { CheckIcon } from '@heroicons/react/24/outline';
import type { Schedule } from './KeychainSchedule';
import DropdownCustomizationPoint from './DropdownCustomizationPoint';

const WhatDays: React.FC<{
  schedule: Schedule;
  setSchedule(schedule: Schedule): void;
  isTouchDevice: boolean;
}> = ({ schedule, setSchedule, isTouchDevice }) => (
  <DropdownCustomizationPoint
    isTouchDevice={isTouchDevice}
    text={(() => {
      switch (true) {
        case Object.values(schedule.days).every((value) => value):
          return `every day`;
        case schedule.days.monday &&
          schedule.days.tuesday &&
          schedule.days.wednesday &&
          schedule.days.thursday &&
          schedule.days.friday &&
          !schedule.days.saturday &&
          !schedule.days.sunday:
          return `weekdays`;
        case !schedule.days.monday &&
          !schedule.days.tuesday &&
          !schedule.days.wednesday &&
          !schedule.days.thursday &&
          !schedule.days.friday &&
          schedule.days.saturday &&
          schedule.days.sunday:
          return `weekends`;
        default: {
          const days = Object.entries(schedule.days).filter(([, value]) => value);
          return days.map(([day], i) =>
            i === days.length - 1 ? (
              <span key={day}>
                {days.length > 1 && <span>and </span>}
                <span className="capitalize">{day.slice(0, 3)}</span>
              </span>
            ) : (
              <span key={day} className="capitalize">
                {day.slice(0, 3)}
                {days.length === 2 ? ` ` : `, `}
              </span>
            ),
          );
        }
      }
    })()}
  >
    <span className="text-xs shrink-0 font-normal text-slate-500">Select days</span>
    <ul className="mt-2">
      {typesafe.objectKeys(schedule.days).map((day) => {
        const selected = schedule.days[day];
        const isOnlyRemaining =
          typesafe.objectEntries(schedule.days).filter(([, value]) => value).length ===
            1 && selected;

        return (
          <li
            key={day}
            className={cx(
              `flex items-center gap-2 cursor-pointer group`,
              isOnlyRemaining && `opacity-50 !cursor-not-allowed`,
            )}
            onClick={() => {
              if (isOnlyRemaining) return;
              setSchedule({
                ...schedule,
                days: {
                  ...schedule.days,
                  [day]: !selected,
                },
              });
            }}
          >
            <div
              className={cx(
                `border w-3 h-3 rounded flex justify-center items-center transition-[background-color,border-color,transform] duration-200`,
                selected ? `border-violet-500 bg-violet-500` : `border-slate-300`,
                !isOnlyRemaining && `group-hover:scale-125`,
              )}
            >
              <CheckIcon
                className={cx(
                  `w-2 text-white transition-[opacity,transform]`,
                  !selected && `opacity-0 scale-0`,
                )}
                strokeWidth={4}
              />
            </div>
            <span
              className={cx(`capitalize`, selected ? `text-slate-900` : `text-slate-500`)}
            >
              {day}
            </span>
          </li>
        );
      })}
    </ul>
  </DropdownCustomizationPoint>
);

export default WhatDays;
