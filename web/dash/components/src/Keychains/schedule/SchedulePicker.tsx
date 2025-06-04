import React from 'react';
import cx from 'classnames';
import type { RuleSchedule } from '@dash/types';
import SpecifyingActiveOrInactive from './SpecifyingActiveOrInactive';
import WhatDays from './WhatDays';
import WhatTime from './WhatTime';

interface Props {
  schedule: RuleSchedule;
  setSchedule(schedule: RuleSchedule): void;
  small?: boolean;
  activeText?: Record<RuleSchedule[`mode`], string>;
}

const SchedulePicker: React.FC<Props> = ({
  schedule,
  setSchedule,
  small,
  activeText = { active: `active`, inactive: `inactive` },
}) => (
  <div
    className={cx(
      `flex justify-center self-center items-center rounded-lg transition-colors duration-200 flex-wrap`,
      small ? `text-sm` : `text-sm @md/schedule:text-base`,
      isTouchDevice()
        ? `bg-transparent gap-1`
        : `bg-transparent gap-1 @[672px]/schedule:gap-0 @[672px]/schedule:bg-slate-200/50 @[672px]/schedule:hover:bg-transparent py-1 px-2`,
    )}
  >
    <SpecifyingActiveOrInactive
      schedule={schedule}
      setSchedule={setSchedule}
      isTouchDevice={isTouchDevice()}
      text={activeText}
    />
    <span className="text-slate-600 px-[3px]">on</span>
    <WhatDays
      schedule={schedule}
      setSchedule={setSchedule}
      isTouchDevice={isTouchDevice()}
    />
    {(schedule.window.start.hour !== 0 ||
      schedule.window.start.minute !== 0 ||
      schedule.window.end.hour !== 23 ||
      schedule.window.end.minute !== 59) && (
      <span className="text-slate-600 px-[3px]">from</span>
    )}
    <WhatTime
      schedule={schedule}
      setSchedule={setSchedule}
      isTouchDevice={isTouchDevice()}
    />
  </div>
);

export default SchedulePicker;

function isTouchDevice(): boolean {
  return `ontouchstart` in window || navigator.maxTouchPoints > 0;
}
