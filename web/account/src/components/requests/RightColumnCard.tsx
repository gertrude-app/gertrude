import { Button } from '@gertrude/ui';
import React from 'react';
import type { ButtonLink } from '#/components/types';

interface Props {
  children: React.ReactNode;
  title: string;
  links?: ButtonLink[];
}

const RightColumnCard: React.FC<Props> = ({ children, title, links }) => (
  <div className="bg-stone-50 border border-stone-200 rounded-2xl p-1.25 flex flex-col gap-0.75">
    <span className="text-xs font-medium text-stone-600 ml-3">{title}</span>
    {children}
    {links && (
      <div className="flex justify-end">
        {links.map((link) => (
          <Button
            key={`${link.href}-${link.text}`}
            type="link"
            href={link.href}
            variant={link.variant}
            icon={link.icon}
            iconPosition={link.iconPosition}
            size="small"
          >
            {link.text}
          </Button>
        ))}
      </div>
    )}
  </div>
);

export default RightColumnCard;
