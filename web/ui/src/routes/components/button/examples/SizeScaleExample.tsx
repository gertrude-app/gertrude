import Button from '#/components/ui/Button';
import { ArrowRightIcon, MailIcon, SearchIcon } from 'lucide-react';
import React from 'react';

type ButtonSize = 'small' | 'medium' | 'large';

const sizes: ButtonSize[] = ['small', 'medium', 'large'];

const SizeScaleExample: React.FC = () => {
  return (
    <div className="flex h-full items-center justify-center p-8">
      <div className="grid gap-4">
        {sizes.map((size) => (
          <div key={size} className="grid items-center gap-3 sm:grid-cols-[5rem_1fr]">
            <div className="font-mono text-xs text-stone-500">{size}</div>
            <div className="flex flex-wrap items-center gap-3">
              <Button
                type="button"
                variant="default"
                size={size}
                onClick={() => undefined}
              >
                Default
              </Button>
              <Button
                type="button"
                variant="default"
                size={size}
                icon={MailIcon}
                onClick={() => undefined}
              >
                Icon left
              </Button>
              <Button
                type="button"
                variant="default"
                size={size}
                icon={ArrowRightIcon}
                iconPosition="right"
                onClick={() => undefined}
              >
                Icon right
              </Button>
              <Button
                type="button"
                variant="default"
                size={size}
                icon={SearchIcon}
                ariaLabel={`${size} search`}
                onClick={() => undefined}
              />
              <Button
                type="button"
                variant="default"
                size={size}
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

export default SizeScaleExample;
