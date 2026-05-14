import Select from '#/components/ui/Select';
import React, { useState } from 'react';

const AssortmentExample: React.FC = () => {
  const [child, setChild] = useState('Sally');
  const [window, setWindow] = useState('After school');

  return (
    <div className="grid h-full place-items-center p-8">
      <div className="grid w-full max-w-3xl items-end gap-5 sm:grid-cols-3">
        <Select
          label="Child"
          selected={child}
          setSelected={setChild}
          possibleValues={['Sally', 'Franny', 'Jimmy']}
        />
        <Select
          selected={window}
          setSelected={setWindow}
          possibleValues={['Morning', 'After school', 'Evening', 'Weekend']}
        />
        <Select
          label="Managed setting"
          selected="School profile"
          setSelected={() => undefined}
          possibleValues={['Parent setting', 'School profile']}
          disabled
        />
      </div>
    </div>
  );
};

export default AssortmentExample;
