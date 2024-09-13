import React from 'react';
import { ClockIcon } from '@heroicons/react/24/outline';
import SpecifyingAllowedOrBlocked from './SpecifyingAllowedOrBlocked';
import WhatDays from './WhatDays';
import WhatTime from './WhatTime';

export type Schedule = {
  specifyingWhen: 'blocked' | 'allowed';
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
  <div className="flex justify-center mt-2 self-center py-1 px-2 items-center bg-slate-200/50 rounded-lg hover:bg-transparent transition-colors duration-200">
    <ClockIcon className="w-4 mr-2 text-slate-400 shrink-0" strokeWidth={2.5} />
    <SpecifyingAllowedOrBlocked schedule={schedule} setSchedule={setSchedule} />
    <span className="text-slate-600 px-[3px]">on</span>
    <WhatDays schedule={schedule} setSchedule={setSchedule} />
    {(schedule.time.start.hour !== 0 ||
      schedule.time.start.minute !== 0 ||
      schedule.time.end.hour !== 23 ||
      schedule.time.end.minute !== 59) && (
      <span className="text-slate-600 px-[3px]">from</span>
    )}
    <WhatTime schedule={schedule} setSchedule={setSchedule} />
  </div>
);

export default KeychainSchedule;
