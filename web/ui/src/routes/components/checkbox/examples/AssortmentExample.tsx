import React, { useState } from 'react';
import Checkbox from '#/components/ui/Checkbox';

const AssortmentExample: React.FC = () => {
  const [requestsEnabled, setRequestsEnabled] = useState(true);
  const [weeklyDigest, setWeeklyDigest] = useState(false);
  const [selectedChildren, setSelectedChildren] = useState(false);

  return (
    <div className="grid h-full place-items-center p-8">
      <div className="grid w-full max-w-2xl gap-5 sm:grid-cols-2">
        <Checkbox
          checked={requestsEnabled}
          setChecked={setRequestsEnabled}
          label="Unlock requests"
          description="Let children ask for access from the block page."
        />
        <Checkbox
          checked={weeklyDigest}
          setChecked={setWeeklyDigest}
          label="Weekly digest"
          description="Email a compact family activity report every Monday."
        />
        <Checkbox
          checked={selectedChildren}
          setChecked={setSelectedChildren}
          indeterminate
          label="Selected children"
          description="Some children already have this rule applied."
        />
        <Checkbox
          checked={true}
          setChecked={() => undefined}
          label="Locked on"
          disabled
        />
        <Checkbox
          checked={false}
          setChecked={() => undefined}
          label="Locked off"
          disabled
        />
        <div className="flex items-center gap-3">
          <Checkbox
            checked={weeklyDigest}
            setChecked={setWeeklyDigest}
            ariaLabel="Compact checkbox"
          />
          <span className="text-sm text-stone-500">Compact unlabeled checkbox</span>
        </div>
      </div>
    </div>
  );
};

export default AssortmentExample;
