'use client';

import { Menu } from '@base-ui/react/menu';
import { ArrowRightIcon, ChevronDownIcon, MenuIcon } from 'lucide-react';
import Link from 'next/link';
import React from 'react';
import Logo from '@/components/Logo';
import HomeButtonLink from '@/components/home/HomeButtonLink';
import { PARENTS_APP_URL } from '@/lib/urls';

const HomeHeader: React.FC = () => {
  const [isScrolled, setIsScrolled] = React.useState(false);
  const [isDark, setIsDark] = React.useState(false);

  React.useEffect(() => {
    const updateScrollState = (): void => {
      setIsScrolled(window.scrollY > 8);
      const darkSections = document.querySelectorAll<HTMLElement>(
        `[data-home-header-theme="dark"]`,
      );
      setIsDark(
        Array.from(darkSections).some((section) => {
          const bounds = section.getBoundingClientRect();
          return bounds.top <= 0 && bounds.bottom >= window.innerHeight;
        }),
      );
    };

    updateScrollState();
    window.addEventListener(`scroll`, updateScrollState, { passive: true });
    window.addEventListener(`resize`, updateScrollState);
    return () => {
      window.removeEventListener(`scroll`, updateScrollState);
      window.removeEventListener(`resize`, updateScrollState);
    };
  }, []);

  return (
    <header
      className={`sticky top-0 z-50 h-[4.5rem] transition-colors duration-300 ${
        isDark ? `text-stone-100` : `text-stone-800`
      }`}
    >
      <div
        className={`relative mx-auto flex items-center justify-between rounded-full border transition-[width,height,max-width,padding,background-color,border-color,box-shadow,transform] duration-300 ease-out motion-reduce:transition-none ${
          isScrolled
            ? isDark
              ? `h-[60px] w-[calc(100%_-_1rem)] max-w-7xl translate-y-2 border-white/10 bg-stone-950/90 px-[11px] shadow-lg shadow-black/25 backdrop-blur-xl`
              : `h-[60px] w-[calc(100%_-_1rem)] max-w-7xl translate-y-2 border-stone-200/90 bg-white/90 px-[11px] shadow-lg shadow-stone-300/30 backdrop-blur-xl`
            : `h-[4.5rem] w-full max-w-[84rem] border-transparent px-4 xs:px-6 lg:px-8`
        }`}
      >
        <Link
          href="/"
          aria-label="Gertrude home"
          className={`rounded-full outline-none transition-transform duration-300 ease-out motion-reduce:transition-none focus-visible:ring-2 focus-visible:ring-violet-400/70 focus-visible:ring-offset-4 ${
            isScrolled ? `translate-x-2` : ``
          }`}
        >
          <span
            className={`relative block h-[25px] overflow-hidden transition-[width] duration-300 ease-out motion-reduce:transition-none ${
              isScrolled ? `w-[25px]` : `w-[138px]`
            }`}
          >
            <Logo
              iconOnly
              size={25}
              type={isDark ? `inverted` : `default`}
              className="absolute left-0 top-0"
            />
            <Logo
              size={25}
              className={`absolute left-0 top-0 transition-opacity duration-300 motion-reduce:transition-none ${
                isScrolled ? `opacity-0` : `opacity-100`
              }`}
            />
          </span>
        </Link>

        <nav
          aria-label="Main navigation"
          className="absolute left-1/2 hidden -translate-x-1/2 items-center gap-0.5 lg:flex"
        >
          <ProductsMenu isDark={isDark} />
          <NavLink href="/#why-gertrude" isDark={isDark}>
            Why Gertrude
          </NavLink>
          <NavLink href="/#pricing" isDark={isDark}>
            Pricing
          </NavLink>
          <NavLink href="/resources" isDark={isDark}>
            Resources
          </NavLink>
        </nav>

        <div className="hidden items-center gap-2 lg:flex">
          <HomeButtonLink href={PARENTS_APP_URL} variant="secondary" inverted={isDark}>
            Log in
          </HomeButtonLink>
          <HomeButtonLink
            href={`${PARENTS_APP_URL}/signup?v=new_site`}
            variant="primary"
            inverted={isDark}
          >
            Get started free
            <ArrowRightIcon className="size-3.5" />
          </HomeButtonLink>
        </div>

        <div className="flex items-center gap-2 lg:hidden">
          <HomeButtonLink
            href={`${PARENTS_APP_URL}/signup?v=new_site`}
            variant="primary"
            inverted={isDark}
            className="hidden xs:inline-flex"
          >
            Get started
          </HomeButtonLink>
          <MobileMenu isDark={isDark} />
        </div>
      </div>
    </header>
  );
};

export default HomeHeader;

const navItemClasses = (isDark: boolean): string =>
  `inline-flex h-9 items-center rounded-full px-3 text-sm font-[450] outline-none transition-colors duration-150 focus-visible:ring-2 focus-visible:ring-violet-400/70 ${
    isDark
      ? `text-stone-300 hover:bg-white/10 hover:text-white data-[popup-open]:bg-white/10 data-[popup-open]:text-white`
      : `text-stone-600 hover:bg-stone-100 hover:text-stone-950 data-[popup-open]:bg-stone-100 data-[popup-open]:text-stone-950`
  }`;

const popupClasses = `origin-[var(--transform-origin)] rounded-xl border border-stone-200 bg-white p-2 text-stone-800 shadow-xl shadow-stone-300/40 outline-none transition-[transform,scale,opacity] duration-150 data-[starting-style]:scale-[0.97] data-[starting-style]:opacity-0 data-[ending-style]:scale-[0.97] data-[ending-style]:opacity-0`;

const menuPositionerClasses = `z-[60] outline-none`;

interface ThemeAwareLinkProps {
  href: string;
  isDark: boolean;
  children: React.ReactNode;
}

const NavLink: React.FC<ThemeAwareLinkProps> = ({ href, isDark, children }) => (
  <Link href={href} className={navItemClasses(isDark)}>
    {children}
  </Link>
);

const MenuTrigger: React.FC<{ isDark: boolean; children: React.ReactNode }> = ({
  isDark,
  children,
}) => (
  <Menu.Trigger className={`${navItemClasses(isDark)} inline-flex items-center gap-1.5`}>
    {children}
    <ChevronDownIcon className="size-3.5 transition-transform duration-150 [[data-popup-open]_&]:rotate-180" />
  </Menu.Trigger>
);

const ProductsMenu: React.FC<{ isDark: boolean }> = ({ isDark }) => (
  <Menu.Root modal={false}>
    <MenuTrigger isDark={isDark}>Products</MenuTrigger>
    <Menu.Portal>
      <Menu.Positioner align="center" sideOffset={10} className={menuPositionerClasses}>
        <Menu.Popup className={`${popupClasses} w-[42rem]`}>
          <div className="grid grid-cols-2 gap-2">
            <ProductGroup title="Internet safety">
              <ProductMenuItem
                href="/mac"
                iconSrc="/app-icons/gertrude.webp"
                title="Gertrude for Mac"
                description="Comprehensive filtering, monitoring, and schedules"
              />
              <ProductMenuItem
                href="/iphone-and-ipad"
                iconSrc="/app-icons/gertrude.webp"
                title="Gertrude Blocker"
                description="Close Screen Time gaps on iPhone and iPad"
              />
            </ProductGroup>
            <ProductGroup title="Curated media">
              <ProductMenuItem
                href="/music"
                iconSrc="/app-icons/music.webp"
                title="Gertrude Music"
                description="A parent-approved Apple Music library"
              />
              <ProductMenuItem
                href="/#media"
                iconSrc="/app-icons/podcasts.webp"
                title="Gertrude Podcasts"
                description="PIN-protected podcast search and listening"
              />
            </ProductGroup>
          </div>
        </Menu.Popup>
      </Menu.Positioner>
    </Menu.Portal>
  </Menu.Root>
);

const ProductGroup: React.FC<{ title: string; children: React.ReactNode }> = ({
  title,
  children,
}) => (
  <div className="rounded-lg bg-stone-50/80 p-1">
    <p className="px-3 pb-1.5 pt-2 text-[11px] font-semibold uppercase tracking-[0.12em] text-stone-400">
      {title}
    </p>
    <div className="space-y-0.5">{children}</div>
  </div>
);

interface ProductMenuItemProps {
  href: string;
  iconSrc: string;
  title: string;
  description: string;
}

const ProductMenuItem: React.FC<ProductMenuItemProps> = ({
  href,
  iconSrc,
  title,
  description,
}) => (
  <Menu.Item
    render={<Link href={href} />}
    className="group flex cursor-pointer items-center gap-3 rounded-lg px-3 py-2.5 outline-none transition-colors duration-150 hover:bg-white data-[highlighted]:bg-white data-[highlighted]:shadow-sm"
  >
    <img
      src={iconSrc}
      alt=""
      width={40}
      height={40}
      decoding="async"
      className="size-10 shrink-0 rounded-[10px]"
    />
    <span className="min-w-0">
      <span className="block text-sm font-semibold text-stone-800 group-hover:text-violet-800 group-data-[highlighted]:text-violet-800">
        {title}
      </span>
      <span className="mt-0.5 block text-xs leading-4 text-stone-500">{description}</span>
    </span>
  </Menu.Item>
);

const MobileMenu: React.FC<{ isDark: boolean }> = ({ isDark }) => (
  <Menu.Root modal={false}>
    <Menu.Trigger
      aria-label="Open navigation"
      className={`flex size-9 items-center justify-center rounded-full border shadow-sm outline-none transition-colors duration-150 focus-visible:ring-2 focus-visible:ring-violet-400/70 ${
        isDark
          ? `border-white/15 bg-white/10 text-stone-100 hover:bg-white/15 data-[popup-open]:bg-white/15`
          : `border-stone-300/80 bg-white text-stone-700 hover:bg-stone-100 data-[popup-open]:bg-stone-100`
      }`}
    >
      <MenuIcon className="size-5" />
    </Menu.Trigger>
    <Menu.Portal>
      <Menu.Positioner align="end" sideOffset={10} className={menuPositionerClasses}>
        <Menu.Popup
          className={`${popupClasses} max-h-[calc(100vh-5.5rem)] w-[calc(100vw-2rem)] max-w-sm overflow-y-auto p-2`}
        >
          <MobileGroupLabel>Products</MobileGroupLabel>
          <MobileLink href="/mac">Gertrude for Mac</MobileLink>
          <MobileLink href="/iphone-and-ipad">Gertrude Blocker</MobileLink>
          <MobileLink href="/music">Gertrude Music</MobileLink>
          <MobileLink href="/#media">Gertrude Podcasts</MobileLink>
          <Menu.Separator className="mx-2 my-2 h-px bg-stone-200" />
          <MobileLink href="/#why-gertrude">Why Gertrude</MobileLink>
          <MobileLink href="/#pricing">Pricing</MobileLink>
          <MobileLink href="/resources">Resources</MobileLink>
          <Menu.Separator className="mx-2 my-2 h-px bg-stone-200" />
          <Menu.Item
            render={<a href={PARENTS_APP_URL} aria-label="Log in" />}
            className="block cursor-pointer rounded-lg px-3 py-2.5 text-sm font-medium text-stone-700 outline-none hover:bg-stone-100 data-[highlighted]:bg-stone-100"
          >
            Log in
          </Menu.Item>
          <Menu.Item
            render={
              <a
                href={`${PARENTS_APP_URL}/signup?v=new_site`}
                aria-label="Get started free"
              />
            }
            className="mt-1 flex cursor-pointer items-center justify-center gap-2 rounded-full border border-violet-800 bg-violet-500 px-3 py-2.5 text-sm font-medium text-white outline-none hover:bg-violet-600 data-[highlighted]:bg-violet-600"
          >
            Get started free
            <ArrowRightIcon className="size-3.5" />
          </Menu.Item>
        </Menu.Popup>
      </Menu.Positioner>
    </Menu.Portal>
  </Menu.Root>
);

const MobileGroupLabel: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <p className="px-3 pb-1 pt-2 text-[11px] font-semibold uppercase tracking-[0.12em] text-stone-400">
    {children}
  </p>
);

const MobileLink: React.FC<{ href: string; children: React.ReactNode }> = ({
  href,
  children,
}) => (
  <Menu.Item
    render={<Link href={href} />}
    className="block cursor-pointer rounded-lg px-3 py-2.5 text-sm font-medium text-stone-700 outline-none hover:bg-stone-100 data-[highlighted]:bg-stone-100"
  >
    {children}
  </Menu.Item>
);
