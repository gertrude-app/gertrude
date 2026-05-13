import Select from '#/components/ui/Select';
import React, { useState } from 'react';

const LabelsExample: React.FC = () => {
  const [labeled, setLabeled] = useState('Homework');
  const [unlabeled, setUnlabeled] = useState('Family iPad');
  const [short, setShort] = useState('Allow');

  return (
    <div className="grid h-full place-items-center p-8">
      <div className="grid w-full max-w-2xl gap-5">
        <Select
          label="Rule preset"
          selected={labeled}
          setSelected={setLabeled}
          possibleValues={['Homework', 'Bedtime', 'Weekend', 'Travel']}
        />
        <div className="grid gap-1.5">
          <div className="text-sm font-medium text-stone-700">Externally labeled</div>
          <Select
            selected={unlabeled}
            setSelected={setUnlabeled}
            possibleValues={['Family iPad', 'Sally’s MacBook', 'Franny’s iPhone']}
          />
        </div>
        <Select
          label="Default action"
          selected={short}
          setSelected={setShort}
          possibleValues={['Allow', 'Block']}
        />
      </div>
    </div>
  );
};

export default LabelsExample;
