'use client';

import * as DropdownMenu from '@radix-ui/react-dropdown-menu';
import cx from 'classnames';
import { ChevronDownIcon } from 'lucide-react';
import Link from 'next/link';
import React from 'react';
import Button from './Button';
import Logo, { type LogoProduct } from './Logo';
import MobileLoginDropdown from './MobileLoginDropdown';
import { PARENTS_APP_URL } from '@/lib/urls';

type HeaderTheme = `violet` | `white`;

const MainHeader: React.FC<{
  theme: HeaderTheme;
  showAuthButtons?: boolean;
  overlay?: boolean;
  logoProduct?: LogoProduct;
  linkVariant?: `default` | `flat`;
  darkAppsDropdown?: boolean;
  compactNavigation?: boolean;
}> = ({
  theme,
  showAuthButtons = true,
  overlay = false,
  logoProduct,
  linkVariant = `default`,
  darkAppsDropdown = false,
  compactNavigation = false,
}) => (
  <header
    className={cx(
      `flex justify-between top-0 left-0 right-0 z-50 py-6`,
      logoProduct ? `items-start` : `items-center`,
      compactNavigation ? `px-4 xs:px-8` : `px-6 xs:px-8`,
      overlay ? `absolute` : `relative`,
    )}
  >
    <a href="/">
      <Logo
        className={cx(`transition-opacity duration-500`)}
        type={theme === `violet` ? `inverted` : `default`}
        product={logoProduct}
      />
    </a>
    <MobileLoginDropdown
      theme={theme}
      alwaysShow={!showAuthButtons}
      dark={darkAppsDropdown}
      compactNavigation={compactNavigation}
    />
    {showAuthButtons && (
      <div
        className={cx(
          `items-center justify-end gap-1.5 transition-opacity duration-500`,
          compactNavigation ? `hidden md+:flex` : `hidden md:flex`,
        )}
      >
        <DesktopAppsDropdown theme={theme} dark={darkAppsDropdown} />
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

const DesktopAppsDropdown: React.FC<{ theme: HeaderTheme; dark: boolean }> = ({
  theme,
  dark,
}) => (
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
        className={cx(
          `z-50 min-w-44 rounded-2xl border p-1.5 shadow-xl backdrop-blur-md`,
          dark
            ? `border-white/10 bg-slate-950/90 shadow-black/30`
            : `border-violet-100 bg-white/90 shadow-black/10`,
        )}
      >
        <DesktopDropdownLink href="/mac" dark={dark}>
          Mac
        </DesktopDropdownLink>
        <DesktopDropdownLink href="/iphone-and-ipad" dark={dark}>
          iPhone &amp; iPad
        </DesktopDropdownLink>
        <DesktopDropdownLink href="/music" dark={dark}>
          Music
        </DesktopDropdownLink>
        <DesktopDropdownLink href="/#podcasts" dark={dark}>
          Podcasts
        </DesktopDropdownLink>
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

const DesktopDropdownLink: React.FC<{
  href: string;
  dark: boolean;
  children: React.ReactNode;
}> = ({ href, dark, children }) => (
  <DropdownMenu.Item asChild>
    <Link
      href={href}
      className={cx(
        `block rounded-xl px-3 py-2 text-sm font-medium transition-colors duration-200 focus:outline-none`,
        dark
          ? `text-violet-100/80 hover:bg-white/10 hover:text-white focus:bg-white/10 focus:text-white`
          : `text-slate-700 hover:bg-violet-100 hover:text-violet-700 focus:bg-violet-100 focus:text-violet-700`,
      )}
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
