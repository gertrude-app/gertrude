'use client';

import * as DropdownMenu from '@radix-ui/react-dropdown-menu';
import cx from 'classnames';
import { MenuIcon } from 'lucide-react';
import Link from 'next/link';
import React from 'react';
import { PARENTS_APP_URL } from '@/lib/urls';

const MobileLoginDropdown: React.FC<{
  theme: `violet` | `white`;
  alwaysShow?: boolean;
}> = ({ theme, alwaysShow = false }) => (
  <DropdownMenu.Root>
    <DropdownMenu.Trigger
      className={cx(
        `hover:scale-105 active:scale-95 transition-transform duration-200`,
        `w-10 h-10 rounded-full flex justify-center items-center`,
        theme === `white` ? `bg-violet-50 text-violet-400` : `bg-white text-slate-400`,
        alwaysShow ? `block` : `sm:hidden block`,
      )}
    >
      <MenuIcon />
    </DropdownMenu.Trigger>
    <DropdownMenu.Portal>
      <DropdownMenu.Content
        className={cx(
          `rounded-xl p-1 mt-2 mr-8 shadow-xl shadow-black/10 backdrop-blur-md`,
          theme === `white` ? `bg-white/70 border border-violet-100` : `bg-white/70`,
        )}
      >
        <DropdownLink href={PARENTS_APP_URL}>Log in</DropdownLink>
        <DropdownLink href={`${PARENTS_APP_URL}/signup?v=new_site`}>Sign up</DropdownLink>
        <DropdownMenu.Separator className="mx-2 my-1 h-px bg-violet-100" />
        <DropdownLink href="/mac">Mac</DropdownLink>
        <DropdownLink href="/iphone-and-ipad">iPhone &amp; iPad</DropdownLink>
        <DropdownLink href="/#podcasts">Gertrude Podcasts</DropdownLink>
        <DropdownLink href="/pricing">Pricing</DropdownLink>
        <DropdownLink href="/docs/faqs">FAQ</DropdownLink>
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
      className="block px-6 py-2 hover:bg-violet-100 hover:text-violet-600 rounded-lg font-medium text-slate-600 transition-[background-color,color,transform] duration-200 active:scale-95 active:bg-violet-200 active:text-violet-700"
    >
      {children}
    </Link>
  </DropdownMenu.Item>
);
