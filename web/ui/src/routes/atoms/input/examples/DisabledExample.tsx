import Input from '#/components/ui/atoms/Input';
import { LockIcon, SearchIcon } from 'lucide-react';
import React, { useState } from 'react';

const DisabledExample: React.FC = () => {
  const [email, setEmail] = useState('parent@example.com');
  const [site, setSite] = useState('gertrude.app');
  const [pin, setPin] = useState('184920');
  const [minutes, setMinutes] = useState('30');

  return (
    <div className="grid h-full place-items-center p-8">
      <div className="grid w-full max-w-3xl gap-5 sm:grid-cols-2">
        <Input
          type="email"
          label="Verified email"
          value={email}
          setValue={setEmail}
          disabled
        />
        <div className="sm:pt-5">
          <Input
            type="text"
            prefix="https://"
            value={site}
            setValue={setSite}
            disabled
            button={{ icon: SearchIcon, ariaLabel: 'Check website', onClick: () => undefined }}
          />
        </div>
        <Input
          type="text"
          label="Claim code"
          value={pin}
          setValue={setPin}
          disabled
          button={{ label: 'Locked', icon: LockIcon, onClick: () => undefined }}
        />
        <div className="sm:pt-5">
          <Input
            type="number"
            suffix="minutes"
            value={minutes}
            setValue={setMinutes}
            disabled
            button={{ label: 'Apply', onClick: () => undefined }}
          />
        </div>
      </div>
    </div>
  );
};

export default DisabledExample;
