import React from 'react';
import { Link } from '@tanstack/react-router';
import cx from 'clsx';
import { type LucideIcon } from 'lucide-react';
import { useSidebarContext } from './SidebarContext';

interface Props {
  title: string;
  icon: LucideIcon;
  href: string;
  selected?: boolean;
  badgeCount?: number;
}

const SidebarItem: React.FC<Props> = ({
  title,
  icon: Icon,
  href,
  selected = false,
  badgeCount,
}) => {
  const { close } = useSidebarContext();
  const isInternalLink = href.startsWith('/') && !href.startsWith('//');
  const linkClassName = cx(
    'flex min-h-9 items-center gap-2.5 rounded-xl px-2.5 py-2 text-left text-stone-900 transition-[background-color,scale] duration-100 outline-none select-none cursor-pointer border relative',
    selected
      ? 'bg-white border-stone-200 min-[940px]:rounded-r-none min-[940px]:-mr-2.5'
      : 'hover:bg-stone-200/50 focus-visible:bg-stone-200/50 active:bg-stone-200/70 border-transparent active:scale-98',
  );
  const content = (
    <>
      {selected && (
        <>
          <div className="bg-white h-full w-0.5 absolute -right-0.5 hidden min-[940px]:block" />
          <div className="bg-white h-4 w-4 absolute -right-0.5 -top-4 justify-center items-center hidden min-[940px]:flex">
            <div className="w-[200%] h-[200%] bg-stone-50 rounded-br-[16px] relative shrink-0 -left-1/2 -top-1/2 border-b border-r border-stone-200" />
          </div>
          <div className="bg-white h-4 w-4 absolute -right-0.5 -bottom-4 justify-center items-center hidden min-[940px]:flex">
            <div className="w-[200%] h-[200%] bg-stone-50 rounded-tr-[16px] relative shrink-0 -left-1/2 -bottom-1/2 border-t border-r border-stone-200" />
          </div>
        </>
      )}
      <Icon className="h-4.5 w-4.5 shrink-0" />
      <span className="flex min-w-0 items-center gap-2">
        <span className="min-w-0 truncate text-[15px] leading-5">{title}</span>
        {badgeCount !== undefined && (
          <span
            className={cx(
              'min-w-5 shrink-0 rounded-full px-1.5 py-0.25 text-center text-xs font-medium leading-5 tabular-nums',
              selected
                ? 'bg-stone-100 text-stone-700'
                : 'bg-stone-200/70 text-stone-600',
            )}
          >
            {badgeCount}
          </span>
        )}
      </span>
    </>
  );

  return (
    <div
      className={cx(
        'relative -mx-2.5 transition-[margin] duration-150',
        selected ? 'my-2 z-0' : 'z-10',
      )}
    >
      {selected && (
        <>
          <div className="absolute w-full h-full shadow-md shadow-stone-300/30 rounded-xl" />
          <div className="absolute bg-gradient-to-r from-transparent to-slate-50 w-[calc(100%+20px)] h-[calc(100%+20px)] -left-2.5 -top-2.5 hidden min-[940px]:block" />
        </>
      )}
      {isInternalLink ? (
        <Link
          to={href}
          className={linkClassName}
          aria-current={selected ? 'page' : undefined}
          onClick={close}
        >
          {content}
        </Link>
      ) : (
        <a
          href={href}
          className={linkClassName}
          aria-current={selected ? 'page' : undefined}
          onClick={close}
        >
          {content}
        </a>
      )}
    </div>
  );
};

export default SidebarItem;
