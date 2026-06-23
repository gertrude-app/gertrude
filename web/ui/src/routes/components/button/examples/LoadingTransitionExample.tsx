import {
  ArrowRightIcon,
  CheckIcon,
  MailIcon,
  RefreshCwIcon,
  SearchIcon,
} from 'lucide-react';
import React, { useState } from 'react';
import Button from '#/components/ui/Button';

const LoadingTransitionExample: React.FC = () => {
  const [loading, setLoading] = useState(false);

  return (
    <div className="grid h-full place-items-center p-8">
      <div className="grid w-full max-w-2xl gap-8 sm:grid-cols-[12rem_1fr] sm:items-start">
        <div className="rounded-2xl border border-stone-200 bg-white p-4 shadow-sm">
          <p className="mb-3 text-sm leading-5 text-stone-500">
            Toggle every button in the stack.
          </p>
          <Button
            type="button"
            variant="primary"
            onClick={() => setLoading((value) => !value)}
          >
            {loading ? `Stop loading` : `Start loading`}
          </Button>
        </div>
        <div className="flex flex-col items-start gap-3">
          <Button
            type="button"
            variant="default"
            loading={loading}
            onClick={() => undefined}
          >
            No icon
          </Button>
          <Button
            type="button"
            variant="primary"
            icon={MailIcon}
            loading={loading}
            onClick={() => undefined}
          >
            Icon left
          </Button>
          <Button
            type="button"
            variant="default"
            icon={ArrowRightIcon}
            iconPosition="right"
            loading={loading}
            onClick={() => undefined}
          >
            Icon right
          </Button>
          <Button
            type="button"
            variant="ghost"
            icon={SearchIcon}
            ariaLabel="Search"
            loading={loading}
            onClick={() => undefined}
          />
          <Button
            type="button"
            variant="destructive"
            icon={RefreshCwIcon}
            iconPosition="right"
            loading={loading}
            onClick={() => undefined}
          >
            Destructive
          </Button>
          <Button
            type="button"
            variant="primary"
            size="large"
            icon={CheckIcon}
            loading={loading}
            onClick={() => undefined}
          >
            Large action
          </Button>
        </div>
      </div>
    </div>
  );
};

export default LoadingTransitionExample;
