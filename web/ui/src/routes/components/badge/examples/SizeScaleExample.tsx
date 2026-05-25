import Badge from '#/components/ui/Badge';
import { CheckIcon } from 'lucide-react';
import React from 'react';

type BadgeSize = 'xsmall' | 'small' | 'medium' | 'large';

const sizes: BadgeSize[] = ['xsmall', 'small', 'medium', 'large'];

const SizeScaleExample: React.FC = () => {
  return (
    <div className="flex h-full items-center justify-center p-8">
      <div className="grid gap-4">
        {sizes.map((size) => (
          <div key={size} className="grid items-center gap-3 sm:grid-cols-[5rem_1fr]">
            <div className="font-mono text-xs text-stone-500">{size}</div>
            <div className="flex flex-wrap items-center gap-3">
              <Badge size={size}>Neutral</Badge>
              <Badge size={size} icon={CheckIcon}>
                Neutral
              </Badge>
              <Badge size={size} color="beta">
                Beta
              </Badge>
              <Badge size={size} color="beta" icon={CheckIcon}>
                Beta
              </Badge>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default SizeScaleExample;
