import { ArrowRightIcon } from 'lucide-react';
import React, { useState } from 'react';
import Input from '#/components/ui/Input';

const HelperAndErrorExample: React.FC = () => {
  const [email, setEmail] = useState(`parent@example.com`);
  const [password, setPassword] = useState(`short`);
  const [website, setWebsite] = useState(``);
  const [minutes, setMinutes] = useState(`0`);

  return (
    <div className="grid h-full place-items-center p-8">
      <div className="grid w-full max-w-3xl gap-5 sm:grid-cols-2">
        <Input
          type="email"
          label="Notification email"
          value={email}
          setValue={setEmail}
          helperText="We’ll send unlock requests and security alerts here."
        />
        <Input
          type="password"
          label="Password"
          value={password}
          setValue={setPassword}
          error="Password must be at least 8 characters."
        />
        <Input
          type="text"
          prefix="https://"
          placeholder="example.com"
          value={website}
          setValue={setWebsite}
          helperText="Enter a hostname without the protocol."
          button={{ label: `Add`, icon: ArrowRightIcon, onClick: () => undefined }}
        />
        <Input
          type="number"
          label="Downtime"
          suffix="minutes"
          value={minutes}
          setValue={setMinutes}
          error="Choose a value greater than zero."
        />
      </div>
    </div>
  );
};

export default HelperAndErrorExample;
