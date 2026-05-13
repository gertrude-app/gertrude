import Select from '#/components/ui/Select';
import React, { useState } from 'react';

const ControlledValuesExample: React.FC = () => {
  const [child, setChild] = useState('Sally');
  const [device, setDevice] = useState('MacBook Pro');
  const [duration, setDuration] = useState('Today');

  return (
    <div className="grid h-full place-items-center p-8">
      <div className="grid w-full max-w-2xl gap-5">
        <div className="rounded-xl border border-stone-200 bg-white p-4 text-sm text-stone-600 shadow-sm">
          Current selection: {child} · {device} · {duration}
        </div>
        <div className="grid gap-4 sm:grid-cols-3">
          <Select
            label="Child"
            selected={child}
            setSelected={setChild}
            possibleValues={['Sally', 'Franny', 'Jimmy']}
          />
          <Select
            label="Device"
            selected={device}
            setSelected={setDevice}
            possibleValues={['MacBook Pro', 'iPad', 'iPhone']}
          />
          <Select
            label="Duration"
            selected={duration}
            setSelected={setDuration}
            possibleValues={['Today', 'This week', 'Always']}
          />
        </div>
      </div>
    </div>
  );
};

export default ControlledValuesExample;
