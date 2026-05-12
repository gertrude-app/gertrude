import Button from '#/components/ui/atoms/Button';
import {
  ArrowRightIcon,
  ExternalLinkIcon,
  MailIcon,
  SearchIcon,
  Trash2Icon,
} from 'lucide-react';
import React from 'react';

const AssortmentExample: React.FC = () => {
  return (
    <div className="flex h-full items-center justify-center p-8">
      <div className="flex max-w-4xl flex-wrap items-center justify-center gap-4">
        <Button type="button" variant="primary" onClick={() => undefined}>
          Create rule
        </Button>
        <Button type="button" variant="default" icon={MailIcon} onClick={() => undefined}>
          Invite parent
        </Button>
        <Button
          type="button"
          variant="primary"
          size="large"
          icon={ArrowRightIcon}
          iconPosition="right"
          onClick={() => undefined}
        >
          Continue setup
        </Button>
        <Button type="button" variant="ghost" size="small" onClick={() => undefined}>
          Skip
        </Button>
        <Button
          type="button"
          variant="default"
          icon={SearchIcon}
          ariaLabel="Search"
          onClick={() => undefined}
        />
        <Button type="button" variant="destructive" icon={Trash2Icon} onClick={() => undefined}>
          Delete
        </Button>
        <Button
          type="button"
          variant="default"
          icon={ArrowRightIcon}
          iconPosition="right"
          loading
          onClick={() => undefined}
        >
          Saving
        </Button>
        <Button type="button" variant="default" disabled onClick={() => undefined}>
          Disabled
        </Button>
        <Button
          type="link"
          href="/atoms/button"
          variant="ghost"
          icon={ExternalLinkIcon}
          iconPosition="right"
        >
          Docs
        </Button>
      </div>
    </div>
  );
};

export default AssortmentExample;
