import { CheckIcon, SearchIcon } from 'lucide-react';
import React, { useState } from 'react';
import Input from '#/components/ui/Input';

const PrefixSuffixExample: React.FC = () => {
  const [url, setUrl] = useState(``);
  const [subdomain, setSubdomain] = useState(`support`);
  const [downtime, setDowntime] = useState(`30`);
  const [version, setVersion] = useState(``);

  return (
    <div className="grid h-full place-items-center p-8">
      <div className="grid w-full max-w-3xl gap-5 sm:grid-cols-2">
        <Input
          type="text"
          label="Website"
          prefix="https://"
          placeholder="gertrude.app"
          value={url}
          setValue={setUrl}
          button={{
            icon: SearchIcon,
            ariaLabel: `Check website`,
            onClick: () => undefined,
          }}
        />
        <div className="sm:pt-5">
          <Input
            type="text"
            suffix=".gertrude.app"
            placeholder="support"
            value={subdomain}
            setValue={setSubdomain}
          />
        </div>
        <Input
          type="number"
          label="Downtime"
          suffix="minutes"
          value={downtime}
          setValue={setDowntime}
          button={{ label: `Set`, icon: CheckIcon, onClick: () => undefined }}
        />
        <div className="sm:pt-5">
          <Input
            type="text"
            prefix="iOS"
            placeholder="18"
            value={version}
            setValue={setVersion}
          />
        </div>
      </div>
    </div>
  );
};

export default PrefixSuffixExample;
