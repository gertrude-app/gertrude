import Button from '#/components/ui/atoms/Button';
import { ArrowRightIcon, MailIcon, SearchIcon } from 'lucide-react';
import React from 'react';

type ButtonVariant = 'primary' | 'default' | 'ghost' | 'destructive';

const variants: ButtonVariant[] = ['primary', 'default', 'ghost', 'destructive'];

const VariantStatesExample: React.FC = () => {
  return (
    <div className="flex h-full items-center justify-center p-8">
      <div className="grid gap-4">
        {variants.map((variant) => (
          <div key={variant} className="grid items-center gap-3 sm:grid-cols-[6.5rem_1fr]">
            <div className="font-mono text-xs text-stone-500">{variant}</div>
            <div className="flex flex-wrap items-center gap-3">
              <Button type="button" variant={variant} onClick={() => undefined}>
                Default
              </Button>
              <Button type="button" variant={variant} icon={MailIcon} onClick={() => undefined}>
                Icon left
              </Button>
              <Button
                type="button"
                variant={variant}
                icon={ArrowRightIcon}
                iconPosition="right"
                onClick={() => undefined}
              >
                Icon right
              </Button>
              <Button
                type="button"
                variant={variant}
                icon={SearchIcon}
                ariaLabel={`${variant} search`}
                onClick={() => undefined}
              />
              <Button
                type="button"
                variant={variant}
                icon={ArrowRightIcon}
                iconPosition="right"
                loading
                onClick={() => undefined}
              >
                Loading
              </Button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default VariantStatesExample;
