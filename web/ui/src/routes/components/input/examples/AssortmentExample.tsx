import Input from '#/components/ui/Input';
import { ArrowRightIcon, SearchIcon } from 'lucide-react';
import React, { useState } from 'react';

const AssortmentExample: React.FC = () => {
  const [childName, setChildName] = useState('Sally');
  const [email, setEmail] = useState('');
  const [site, setSite] = useState('school.edu');
  const [dailyLimit, setDailyLimit] = useState('');

  return (
    <div className="grid h-full place-items-center p-8">
      <div className="grid w-full max-w-3xl gap-5 sm:grid-cols-2">
        <Input
          type="text"
          name="childName"
          autoComplete="given-name"
          label="Child name"
          placeholder="Franny"
          value={childName}
          setValue={setChildName}
        />
        <div className="sm:pt-5">
          <Input
            type="email"
            name="email"
            autoComplete="email"
            required
            placeholder="parent@example.com"
            value={email}
            setValue={setEmail}
            button={{ label: 'Invite', icon: ArrowRightIcon, onClick: () => undefined }}
          />
        </div>
        <Input
          type="text"
          label="Allowed website"
          prefix="https://"
          placeholder="example.com"
          value={site}
          setValue={setSite}
          button={{ label: 'Check', icon: SearchIcon, onClick: () => undefined }}
        />
        <div className="sm:pt-5">
          <Input
            type="number"
            placeholder="45"
            suffix="minutes"
            value={dailyLimit}
            setValue={setDailyLimit}
          />
        </div>
      </div>
    </div>
  );
};

export default AssortmentExample;
