import React, { useState } from 'react';
import Toggle from '#/components/ui/Toggle';

const StatesExample: React.FC = () => {
  const [enabled, setEnabled] = useState(true);
  const [disabled, setDisabled] = useState(false);

  return (
    <div className="grid h-full place-items-center p-8">
      <div className="grid w-full max-w-2xl gap-5 sm:grid-cols-4">
        <div className="grid gap-2">
          <span className="font-mono text-xs text-stone-500">on</span>
          <Toggle checked={enabled} setChecked={setEnabled} />
        </div>
        <div className="grid gap-2">
          <span className="font-mono text-xs text-stone-500">off</span>
          <Toggle checked={disabled} setChecked={setDisabled} />
        </div>
        <div className="grid gap-2">
          <span className="font-mono text-xs text-stone-500">on disabled</span>
          <Toggle checked={true} setChecked={() => undefined} disabled />
        </div>
        <div className="grid gap-2">
          <span className="font-mono text-xs text-stone-500">off disabled</span>
          <Toggle checked={false} setChecked={() => undefined} disabled />
        </div>
      </div>
    </div>
  );
};

export default StatesExample;
