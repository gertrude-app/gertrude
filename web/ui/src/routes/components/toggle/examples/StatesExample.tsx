import React, { useState } from 'react';
import Toggle from '#/components/ui/Toggle';

const StatesExample: React.FC = () => {
  const [enabled, setEnabled] = useState(true);
  const [disabled, setDisabled] = useState(false);
  const [smallEnabled, setSmallEnabled] = useState(true);
  const [smallDisabled, setSmallDisabled] = useState(false);

  return (
    <div className="grid h-full place-items-center p-8">
      <div className="grid w-full max-w-3xl gap-5 sm:grid-cols-6">
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
        <div className="grid gap-2">
          <span className="font-mono text-xs text-stone-500">small on</span>
          <Toggle checked={smallEnabled} setChecked={setSmallEnabled} small />
        </div>
        <div className="grid gap-2">
          <span className="font-mono text-xs text-stone-500">small off</span>
          <Toggle checked={smallDisabled} setChecked={setSmallDisabled} small />
        </div>
      </div>
    </div>
  );
};

export default StatesExample;
