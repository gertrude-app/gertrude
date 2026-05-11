import React, { useState } from 'react';
import { Link } from '@tanstack/react-router';
import cx from 'clsx';
import { ChevronRightIcon, type LucideIcon } from 'lucide-react';

type Props = {
  title: string;
  icon: LucideIcon;
} & (
  | {
      to: string;
    }
  | {
      children: React.ReactNode;
    }
);

const itemClassName =
  'flex items-center justify-between hover:bg-stone-200/30 px-2 py-1.5 rounded-xl -mx-2 cursor-default active:bg-stone-200/50 active:scale-98 transition-[scale] duration-100 select-none';

const SidebarItem: React.FC<Props> = ({ title, icon: Icon, ...props }) => {
  const [isOpen, setIsOpen] = useState(false);

  const content = (
    <div className="flex items-center gap-2 text-stone-900">
      <Icon className="w-4 h-4" />
      <span className="text-sm">{title}</span>
    </div>
  );

  return (
    <div className="flex flex-col">
      {'to' in props ? (
        <Link to={props.to} className={itemClassName}>
          {content}
        </Link>
      ) : (
        <>
          <div onClick={() => setIsOpen(!isOpen)} className={itemClassName}>
            {content}
            <ChevronRightIcon
              className={cx(
                'w-4 h-4 transition-transform duration-100 text-stone-900',
                isOpen && 'rotate-90',
              )}
            />
          </div>

          <div
            className={cx(
              isOpen ? 'h-auto opacity-100' : 'h-0 opacity-0',
              'overflow-hidden transition-[height,opacity] duration-150 -mr-2',
            )}
          >
            {props.children}
          </div>
        </>
      )}
    </div>
  );
};

export default SidebarItem;
