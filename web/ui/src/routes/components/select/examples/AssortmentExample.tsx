import { CalendarDaysIcon, ClockIcon, MoonIcon, SunIcon } from 'lucide-react';
import React, { useState } from 'react';
import Select from '#/components/ui/Select';

const childOptions = [`Sally`, `Franny`, `Jimmy`] as const;
const windowOptions = [
  {
    value: `morning`,
    label: `Morning`,
    description: `Before school starts.`,
    icon: SunIcon,
  },
  {
    value: `afterSchool`,
    label: `After school`,
    description: `Until dinner time.`,
    icon: ClockIcon,
  },
  {
    value: `evening`,
    label: `Evening`,
    description: `After dinner hours.`,
    icon: MoonIcon,
  },
  {
    value: `weekend`,
    label: `Weekend`,
    description: `Saturday and Sunday.`,
    icon: CalendarDaysIcon,
  },
] as const;

const AssortmentExample: React.FC = () => {
  const [child, setChild] = useState<(typeof childOptions)[number]>(`Sally`);
  const [window, setWindow] =
    useState<(typeof windowOptions)[number][`value`]>(`afterSchool`);

  return (
    <div className="grid h-full place-items-center p-8">
      <div className="grid w-full max-w-3xl items-end gap-5 sm:grid-cols-3">
        <Select
          label="Small child"
          selected={child}
          setSelected={setChild}
          possibleValues={childOptions}
          size="small"
        />
        <Select
          label="Medium window"
          selected={window}
          setSelected={setWindow}
          possibleValues={windowOptions}
        />
        <Select
          label="Managed"
          labelPosition="left"
          selected="School profile"
          setSelected={() => undefined}
          possibleValues={[`Parent setting`, `School profile`]}
          disabled
        />
      </div>
    </div>
  );
};

export default AssortmentExample;
