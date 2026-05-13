import Input from '#/components/ui/Input';
import { ArrowRightIcon, CheckIcon, CopyIcon, SearchIcon } from 'lucide-react';
import React, { useState } from 'react';

const ButtonActionExample: React.FC = () => {
  const [inviteEmail, setInviteEmail] = useState('');
  const [unlockUrl, setUnlockUrl] = useState('wikipedia.org');
  const [claimCode, setClaimCode] = useState('184920');
  const [minutes, setMinutes] = useState('');

  return (
    <div className="grid h-full place-items-center p-8">
      <div className="grid w-full max-w-3xl gap-5 sm:grid-cols-2">
        <Input
          type="email"
          name="inviteEmail"
          autoComplete="email"
          required
          label="Invite parent"
          placeholder="you@example.com"
          value={inviteEmail}
          setValue={setInviteEmail}
          button={{ label: 'Send', icon: ArrowRightIcon, onClick: () => undefined }}
        />
        <div className="sm:pt-5">
          <Input
            type="text"
            prefix="https://"
            value={unlockUrl}
            setValue={setUnlockUrl}
            button={{ label: 'Review', icon: SearchIcon, onClick: () => undefined }}
          />
        </div>
        <Input
          type="text"
          label="Claim code"
          placeholder="123456"
          value={claimCode}
          setValue={setClaimCode}
          button={{
            icon: CopyIcon,
            ariaLabel: 'Copy claim code',
            onClick: () => undefined,
          }}
        />
        <div className="sm:pt-5">
          <Input
            type="number"
            placeholder="15"
            suffix="minutes"
            value={minutes}
            setValue={setMinutes}
            button={{ label: 'Apply', icon: CheckIcon, onClick: () => undefined }}
          />
        </div>
      </div>
    </div>
  );
};

export default ButtonActionExample;
