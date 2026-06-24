'use client';

import * as DropdownMenu from '@radix-ui/react-dropdown-menu';
import cx from 'classnames';
import { ChevronDownIcon } from 'lucide-react';
import Link from 'next/link';
import React from 'react';
import Button from './Button';
import Logo from './Logo';
import MobileLoginDropdown from './MobileLoginDropdown';
import { PARENTS_APP_URL } from '@/lib/urls';

type HeaderTheme = `violet` | `white`;

const MainHeader: React.FC<{
  theme: HeaderTheme;
  showAuthButtons?: boolean;
  overlay?: boolean;
  badge?: string;
  linkVariant?: `default` | `flat`;
}> = ({
  theme,
  showAuthButtons = true,
  overlay = false,
  badge,
  linkVariant = `default`,
}) => (
  <header
    className={cx(
      `flex justify-between items-center px-6 xs:px-8 top-0 left-0 right-0 z-50 py-6`,
      overlay ? `absolute` : `relative`,
    )}
  >
    <a href="/">
      <Logo
        className={cx(`transition-opacity duration-500`)}
        type={theme === `violet` ? `inverted` : `default`}
        badge={badge}
      />
    </a>
    <MobileLoginDropdown theme={theme} alwaysShow={!showAuthButtons} />
    {showAuthButtons && (
      <div className="hidden md:flex items-center justify-end gap-1.5 transition-opacity duration-500">
        <DesktopAppsDropdown theme={theme} />
        <DesktopNavLink href="/pricing" theme={theme}>
          Pricing
        </DesktopNavLink>
        <DesktopNavLink href="/blog" theme={theme}>
          Blog
        </DesktopNavLink>
        <DesktopNavLink href="/contact" theme={theme}>
          Contact
        </DesktopNavLink>
        <Button
          type="link"
          href={PARENTS_APP_URL}
          size="xs"
          color="secondary"
          inverted={theme === `violet`}
          variant={linkVariant}
          className="ml-1 whitespace-nowrap"
        >
          Log in
        </Button>
        <Button
          type="link"
          href={`${PARENTS_APP_URL}/signup?v=new_site`}
          size="xs"
          color="primary"
          inverted={theme === `violet`}
          className="whitespace-nowrap"
        >
          Sign up
        </Button>
      </div>
    )}
  </header>
);

export default MainHeader;

const DesktopAppsDropdown: React.FC<{ theme: HeaderTheme }> = ({ theme }) => (
  <DropdownMenu.Root>
    <DropdownMenu.Trigger
      type="button"
      className={cx(desktopNavClass(theme), `inline-flex items-center gap-1`)}
    >
      Apps
      <ChevronDownIcon className="size-3.5" />
    </DropdownMenu.Trigger>
    <DropdownMenu.Portal>
      <DropdownMenu.Content
        align="end"
        sideOffset={8}
        className="z-50 min-w-44 rounded-2xl border border-violet-100 bg-white/90 p-1.5 shadow-xl shadow-black/10 backdrop-blur-md"
      >
        <DesktopDropdownLink href="/mac">Mac</DesktopDropdownLink>
        <DesktopDropdownLink href="/iphone-and-ipad">
          iPhone &amp; iPad
        </DesktopDropdownLink>
        <DesktopDropdownLink href="/#podcasts">Podcasts</DesktopDropdownLink>
      </DropdownMenu.Content>
    </DropdownMenu.Portal>
  </DropdownMenu.Root>
);

const DesktopNavLink: React.FC<{
  href: string;
  theme: HeaderTheme;
  children: React.ReactNode;
}> = ({ href, theme, children }) => (
  <Link href={href} className={desktopNavClass(theme)}>
    {children}
  </Link>
);

const DesktopDropdownLink: React.FC<{ href: string; children: React.ReactNode }> = ({
  href,
  children,
}) => (
  <DropdownMenu.Item asChild>
    <Link
      href={href}
      className="block rounded-xl px-3 py-2 text-sm font-medium text-slate-700 transition-colors duration-200 hover:bg-violet-100 hover:text-violet-700 focus:bg-violet-100 focus:text-violet-700 focus:outline-none"
    >
      {children}
    </Link>
  </DropdownMenu.Item>
);

function desktopNavClass(theme: HeaderTheme): string {
  return cx(
    `rounded-full px-3 py-2 text-sm font-semibold transition-colors duration-200`,
    theme === `violet`
      ? `text-white/85 hover:bg-white/10 hover:text-white`
      : `text-violet-700 hover:bg-violet-100 hover:text-violet-900`,
  );
}
