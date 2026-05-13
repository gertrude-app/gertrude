import Button from '#/components/ui/atoms/Button';
import Input from '#/components/ui/atoms/Input';
import { ArrowRightIcon, PlusIcon, SearchIcon } from 'lucide-react';
import React, { useState } from 'react';

const InlineButtonExample: React.FC = () => {
  const [inviteEmail, setInviteEmail] = useState('');
  const [allowedSite, setAllowedSite] = useState('khanacademy.org');
  const [unlockRequest, setUnlockRequest] = useState('minecraft.net');

  return (
    <div className="grid h-full place-items-center p-8">
      <div className="flex w-full max-w-xl flex-col gap-5">
        <form
          className="flex items-end gap-2.5"
          onSubmit={(event) => event.preventDefault()}
        >
          <div className="min-w-0 flex-grow">
            <Input
              type="email"
              name="parentEmail"
              autoComplete="email"
              required
              label="Invite parent"
              placeholder="you@example.com"
              value={inviteEmail}
              setValue={setInviteEmail}
            />
          </div>
          <Button type="submit" variant="primary" icon={ArrowRightIcon}>
            Send invite
          </Button>
        </form>

        <div className="flex items-end gap-2.5">
          <div className="min-w-0 flex-grow">
            <Input
              type="text"
              label="Allowed website"
              prefix="https://"
              placeholder="example.com"
              value={allowedSite}
              setValue={setAllowedSite}
            />
          </div>
          <Button type="button" onClick={() => undefined} icon={PlusIcon}>
            Add site
          </Button>
        </div>

        <div className="flex items-end gap-2.5">
          <div className="min-w-0 flex-grow">
            <Input
              type="text"
              label="Unlock request"
              placeholder="domain.com"
              value={unlockRequest}
              setValue={setUnlockRequest}
            />
          </div>
          <Button type="button" onClick={() => undefined} variant="ghost" icon={SearchIcon}>
            Review
          </Button>
        </div>
      </div>
    </div>
  );
};

export default InlineButtonExample;
