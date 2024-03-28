'use client';

import { MenuIcon } from 'lucide-react';
import * as DropdownMenu from '@radix-ui/react-dropdown-menu';
import React from 'react';
import Link from 'next/link';
import cx from 'classnames';

const MobileLoginDropdown: React.FC<{ theme: `violet` | `white` }> = ({ theme }) => (
  <DropdownMenu.Root>
    <DropdownMenu.Trigger
      className={cx(
        `sm:hidden block hover:scale-105 active:scale-95 transition-transform duration-200`,
        `w-10 h-10 rounded-full flex justify-center items-center`,
        theme === `white` ? `bg-violet-50 text-violet-400` : `bg-white text-slate-400`,
      )}
    >
      <MenuIcon />
    </DropdownMenu.Trigger>
    <DropdownMenu.Portal>
      <DropdownMenu.Content
        className={cx(
          `rounded-xl p-1 mt-2 mr-8`,
          theme === `white` ? `bg-violet-100/50` : `bg-white`,
        )}
      >
        <DropdownLink href="https://parents.gertrude.app/signup">Sign up</DropdownLink>
        <DropdownLink href="https://parents.gertrude.app">Log in</DropdownLink>
      </DropdownMenu.Content>
    </DropdownMenu.Portal>
  </DropdownMenu.Root>
);

export default MobileLoginDropdown;

const DropdownLink: React.FC<{ href: string; children: React.ReactNode }> = ({
  href,
  children,
}) => (
  <DropdownMenu.Item>
    <Link
      href={href}
      className="block px-4 py-2 hover:bg-violet-100 hover:text-violet-600 rounded-lg font-medium text-slate-600 transition-[background-color,color,transform] duration-200 active:scale-95 active:bg-violet-200 active:text-violet-700"
    >
      {children}
    </Link>
  </DropdownMenu.Item>
);
