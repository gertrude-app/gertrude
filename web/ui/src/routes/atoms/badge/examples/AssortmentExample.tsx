import Badge from '#/components/ui/atoms/Badge';
import { CheckIcon, ClockIcon, ShieldAlertIcon, SparklesIcon } from 'lucide-react';
import React from 'react';

const AssortmentExample: React.FC = () => {
  return (
    <div className="flex h-full items-center justify-center p-8">
      <div className="flex max-w-3xl flex-wrap items-center justify-center gap-3">
        <Badge color="neutral">Draft</Badge>
        <Badge color="violet" icon={SparklesIcon}>
          New
        </Badge>
        <Badge color="green" icon={CheckIcon}>
          Active
        </Badge>
        <Badge color="yellow" icon={ClockIcon}>
          Waiting
        </Badge>
        <Badge color="red" icon={ShieldAlertIcon}>
          Needs review
        </Badge>
        <Badge size="small" color="blue">
          macOS
        </Badge>
        <Badge size="large" color="blue" icon={SparklesIcon}>
          Managed
        </Badge>
      </div>
    </div>
  );
};

export default AssortmentExample;
