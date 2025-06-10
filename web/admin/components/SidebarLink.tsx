'use client';

import cx from 'classnames';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import React from 'react';

interface Props {
  href: string;
  children: React.ReactNode;
}

const SidebarLink: React.FC<Props> = ({ href, children }) => {
  const path = usePathname();
  return (
    <Link
      href={href}
      className={cx(
        `px-4 py-2 rounded-xl font-medium text-lg transition-[background-color,color,box-shadow] duration-300`,
        href === path ? `bg-white shadow-md shadow-violet-900/5` : `hover:bg-violet-100`,
      )}
    >
      <span
        className={cx(
          `w-fit`,
          href === path
            ? `bg-gradient-to-r from-violet-600 to-fuchsia-500 text-transparent bg-clip-text`
            : `text-slate-700`,
        )}
      >
        {children}
      </span>
    </Link>
  );
};

export default SidebarLink;
