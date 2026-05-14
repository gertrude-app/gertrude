import RadioGroup from '#/components/ui/RadioGroup';
import React, { useState } from 'react';

const AssortmentExample: React.FC = () => {
  const [schedule, setSchedule] = useState('Homework first');
  const [duration, setDuration] = useState('Today');
  const [managed, setManaged] = useState('School profile');

  return (
    <div className="grid h-full place-items-center p-8">
      <div className="grid w-full max-w-3xl items-start gap-8 sm:grid-cols-3">
        <RadioGroup
          label="Rule mode"
          selected={schedule}
          setSelected={setSchedule}
          possibleValues={['Homework first', 'Bedtime', 'Weekend']}
        />
        <RadioGroup
          label="Duration"
          direction="horizontal"
          selected={duration}
          setSelected={setDuration}
          possibleValues={['Today', 'This week', 'Always']}
        />
        <RadioGroup
          label="Managed setting"
          selected={managed}
          setSelected={setManaged}
          possibleValues={['Parent setting', 'School profile']}
          disabled
        />
      </div>
    </div>
  );
};

export default AssortmentExample;
