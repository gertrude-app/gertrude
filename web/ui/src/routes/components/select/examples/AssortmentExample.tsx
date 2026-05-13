import Select from '#/components/ui/Select';
import React, { useState } from 'react';

const AssortmentExample: React.FC = () => {
  const [child, setChild] = useState('Sally');
  const [status, setStatus] = useState('Active');
  const [window, setWindow] = useState('After school');

  return (
    <div className="grid h-full place-items-center p-8">
      <div className="grid w-full max-w-3xl gap-5 sm:grid-cols-3">
        <Select
          label="Child"
          selected={child}
          setSelected={setChild}
          possibleValues={['Sally', 'Franny', 'Jimmy']}
        />
        <Select
          label="Status"
          selected={status}
          setSelected={setStatus}
          possibleValues={['Active', 'Paused', 'Needs review', 'Archived']}
        />
        <Select
          label="Window"
          selected={window}
          setSelected={setWindow}
          possibleValues={['Morning', 'After school', 'Evening', 'Weekend']}
        />
      </div>
    </div>
  );
};

export default AssortmentExample;
