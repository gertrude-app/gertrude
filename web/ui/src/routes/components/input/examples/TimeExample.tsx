import React, { useState } from 'react';
import Input from '#/components/ui/Input';

const TimeExample: React.FC = () => {
  const [schoolStart, setSchoolStart] = useState(`08:30`);
  const [quietHours, setQuietHours] = useState(`20:00`);

  return (
    <div className="grid h-full place-items-center p-8">
      <div className="grid w-full max-w-lg gap-5 sm:grid-cols-2">
        <Input
          type="time"
          label="School starts"
          value={schoolStart}
          setValue={setSchoolStart}
        />
        <Input
          type="time"
          label="Quiet hours"
          value={quietHours}
          setValue={setQuietHours}
        />
      </div>
    </div>
  );
};

export default TimeExample;
