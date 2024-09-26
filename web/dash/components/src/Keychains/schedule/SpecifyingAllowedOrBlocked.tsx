import React from 'react';
import { ArrowsRightLeftIcon } from '@heroicons/react/24/outline';
import type { Schedule } from './KeychainSchedule';

const SpecifyingAllowedOrBlocked: React.FC<{
  schedule: Schedule;
  setSchedule(schedule: Schedule): void;
}> = ({ schedule, setSchedule }) => (
  <button
    className="capitalize font-medium flex items-center group hover:bg-slate-200 px-[3px] hover:px-2 py-0.5 rounded-lg active:scale-90 active:bg-slate-300 transition-[transform,background-color,margin,padding] duration-200"
    onClick={() =>
      setSchedule({
        ...schedule,
        specifyingWhen: schedule.specifyingWhen === `active` ? `inactive` : `active`,
      })
    }
  >
    <span className="text-slate-700">{schedule.specifyingWhen}</span>
    <ArrowsRightLeftIcon
      className="shrink-0 w-0 ml-0 group-hover:w-4 group-hover:ml-2 transition-[width,margin-left,filter] text-slate-400 duration-200"
      strokeWidth={2.5}
    />
  </button>
);

export default SpecifyingAllowedOrBlocked;
