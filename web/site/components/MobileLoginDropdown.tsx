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
  dark?: boolean;
  compactNavigation?: boolean;
}> = ({ theme, alwaysShow = false, dark = false, compactNavigation = false }) => (
  <DropdownMenu.Root>
    <DropdownMenu.Trigger
      type="button"
      aria-label="Open navigation"
      className={cx(
        `flex size-10 items-center justify-center rounded-full transition-transform duration-200 hover:scale-105 active:scale-95`,
        dark
          ? `border border-white/15 bg-white/10 text-white backdrop-blur-sm`
          : theme === `white`
            ? `bg-violet-50 text-violet-400`
            : `bg-white text-slate-400`,
        !alwaysShow && (compactNavigation ? `md+:hidden` : `md:hidden`),
      )}
    >
      <MenuIcon />
    </DropdownMenu.Trigger>
    <DropdownMenu.Portal>
      <DropdownMenu.Content
        align="end"
        sideOffset={8}
        className={cx(
          `z-50 max-h-[calc(100vh-5rem)] min-w-56 overflow-y-auto rounded-2xl border p-1.5 shadow-xl backdrop-blur-md`,
          dark
            ? `border-white/10 bg-slate-950/95 shadow-black/30`
            : theme === `white`
              ? `border-violet-100 bg-white/80 shadow-black/10`
              : `border-transparent bg-white/80 shadow-black/10`,
        )}
      >
        <DropdownLink href={PARENTS_APP_URL} dark={dark}>
          Log in
        </DropdownLink>
        <DropdownLink href={`${PARENTS_APP_URL}/signup?v=new_site`} dark={dark}>
          Sign up
        </DropdownLink>
        <DropdownMenu.Separator
          className={cx(`mx-2 my-1 h-px`, dark ? `bg-white/10` : `bg-violet-100`)}
        />
        <DropdownLink href="/mac" dark={dark}>
          Mac
        </DropdownLink>
        <DropdownLink href="/iphone-and-ipad" dark={dark}>
          iPhone &amp; iPad
        </DropdownLink>
        <DropdownLink href="/music" dark={dark}>
          Gertrude Music
        </DropdownLink>
        <DropdownLink href="/#podcasts" dark={dark}>
          Gertrude Podcasts
        </DropdownLink>
        <DropdownLink href="/pricing" dark={dark}>
          Pricing
        </DropdownLink>
        <DropdownLink href="/resources" dark={dark}>
          Resources
        </DropdownLink>
        <DropdownLink href="/contact" dark={dark}>
          Contact
        </DropdownLink>
      </DropdownMenu.Content>
    </DropdownMenu.Portal>
  </DropdownMenu.Root>
);

export default MobileLoginDropdown;

const DropdownLink: React.FC<{
  href: string;
  dark: boolean;
  children: React.ReactNode;
}> = ({ href, dark, children }) => (
  <DropdownMenu.Item asChild>
    <Link
      href={href}
      className={cx(
        `block rounded-xl px-5 py-2.5 font-medium transition-[background-color,color,transform] duration-200 focus:outline-none active:scale-[0.98]`,
        dark
          ? `text-violet-100/80 hover:bg-white/10 hover:text-white focus:bg-white/10 focus:text-white active:bg-white/15`
          : `text-slate-600 hover:bg-violet-100 hover:text-violet-600 focus:bg-violet-100 focus:text-violet-600 active:bg-violet-200 active:text-violet-700`,
      )}
    >
      {children}
    </Link>
  </DropdownMenu.Item>
);
