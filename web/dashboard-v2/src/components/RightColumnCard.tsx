import { Button } from '@gertrude/ui';
import type { LucideIcon } from 'lucide-react';
import React from 'react';

interface Props {
  children: React.ReactNode;
  title: string;
  links?: Array<{
    text: string;
    href: string;
    variant?: 'ghost' | 'default';
    icon?: LucideIcon;
    iconPosition?: 'left' | 'right';
  }>;
}

const RightColumnCard: React.FC<Props> = ({ children, title, links }) => {
  return (
    <div className="bg-stone-50 border border-stone-200 rounded-2xl p-1.25 flex flex-col gap-0.75">
      <span className="text-xs font-medium text-stone-600 ml-3">{title}</span>
      {children}
      {links && (
        <div className="flex justify-end">
          {links.map((l) => (
            <Button
              key={`${l.href}-${l.text}`}
              type="link"
              href={l.href}
              variant={l.variant}
              icon={l.icon}
              iconPosition={l.iconPosition}
              size="small"
            >
              {l.text}
            </Button>
          ))}
        </div>
      )}
    </div>
  );
};

export default RightColumnCard;
