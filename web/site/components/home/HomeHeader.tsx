'use client';

import { Menu } from '@base-ui/react/menu';
import {
  ArrowRightIcon,
  BookOpenIcon,
  ChevronDownIcon,
  MailIcon,
  MenuIcon,
  NewspaperIcon,
} from 'lucide-react';
import Link from 'next/link';
import React from 'react';
import Logo from '@/components/Logo';
import HomeButtonLink from '@/components/home/HomeButtonLink';
import { PARENTS_APP_URL } from '@/lib/urls';

const HomeHeader: React.FC = () => {
  const [isScrolled, setIsScrolled] = React.useState(false);

  React.useEffect(() => {
    const updateScrollState = (): void => setIsScrolled(window.scrollY > 8);
    updateScrollState();
    window.addEventListener(`scroll`, updateScrollState, { passive: true });
    return () => window.removeEventListener(`scroll`, updateScrollState);
  }, []);

  return (
    <header className="sticky top-0 z-50 h-[4.5rem] text-stone-800">
      <div
        className={`relative mx-auto flex items-center justify-between rounded-full border transition-[width,height,max-width,padding,background-color,border-color,box-shadow,transform] duration-300 ease-out motion-reduce:transition-none ${
          isScrolled
            ? `h-[60px] w-[calc(100%_-_1rem)] max-w-7xl translate-y-2 border-stone-200/90 bg-white/90 px-[11px] shadow-lg shadow-stone-300/30 backdrop-blur-xl`
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
            <Logo iconOnly size={25} className="absolute left-0 top-0" />
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
          <ProductsMenu />
          <NavLink href="/#why-gertrude">Why Gertrude</NavLink>
          <NavLink href="/#pricing">Pricing</NavLink>
          <ResourcesMenu />
        </nav>

        <div className="hidden items-center gap-2 lg:flex">
          <HomeButtonLink href={PARENTS_APP_URL} variant="secondary">
            Log in
          </HomeButtonLink>
          <HomeButtonLink href={`${PARENTS_APP_URL}/signup?v=new_site`} variant="primary">
            Get started free
            <ArrowRightIcon className="size-3.5" />
          </HomeButtonLink>
        </div>

        <div className="flex items-center gap-2 lg:hidden">
          <HomeButtonLink
            href={`${PARENTS_APP_URL}/signup?v=new_site`}
            variant="primary"
            className="hidden xs:inline-flex"
          >
            Get started
          </HomeButtonLink>
          <MobileMenu />
        </div>
      </div>
    </header>
  );
};

export default HomeHeader;

const navItemClasses = `inline-flex h-9 items-center rounded-full px-3 text-sm font-[450] text-stone-600 outline-none transition-colors duration-150 hover:bg-stone-100 hover:text-stone-950 focus-visible:ring-2 focus-visible:ring-violet-400/70 data-[popup-open]:bg-stone-100 data-[popup-open]:text-stone-950`;

const popupClasses = `origin-[var(--transform-origin)] rounded-xl border border-stone-200 bg-white p-2 text-stone-800 shadow-xl shadow-stone-300/40 outline-none transition-[transform,scale,opacity] duration-150 data-[starting-style]:scale-[0.97] data-[starting-style]:opacity-0 data-[ending-style]:scale-[0.97] data-[ending-style]:opacity-0`;

const menuPositionerClasses = `z-[60] outline-none`;

const NavLink: React.FC<{ href: string; children: React.ReactNode }> = ({
  href,
  children,
}) => (
  <Link href={href} className={navItemClasses}>
    {children}
  </Link>
);

const MenuTrigger: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <Menu.Trigger className={`${navItemClasses} inline-flex items-center gap-1.5`}>
    {children}
    <ChevronDownIcon className="size-3.5 transition-transform duration-150 [[data-popup-open]_&]:rotate-180" />
  </Menu.Trigger>
);

const ProductsMenu: React.FC = () => (
  <Menu.Root modal={false}>
    <MenuTrigger>Products</MenuTrigger>
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
    <img src={iconSrc} alt="" className="size-10 shrink-0 rounded-[10px]" />
    <span className="min-w-0">
      <span className="block text-sm font-semibold text-stone-800 group-hover:text-violet-800 group-data-[highlighted]:text-violet-800">
        {title}
      </span>
      <span className="mt-0.5 block text-xs leading-4 text-stone-500">{description}</span>
    </span>
  </Menu.Item>
);

const ResourcesMenu: React.FC = () => (
  <Menu.Root modal={false}>
    <MenuTrigger>Resources</MenuTrigger>
    <Menu.Portal>
      <Menu.Positioner align="end" sideOffset={10} className={menuPositionerClasses}>
        <Menu.Popup className={`${popupClasses} w-72`}>
          <ResourceMenuItem
            href="/blog"
            icon={NewspaperIcon}
            title="Blog"
            description="Guidance for protecting kids online"
          />
          <ResourceMenuItem
            href="/docs/getting-started"
            icon={BookOpenIcon}
            title="Help and documentation"
            description="Setup guides and product help"
          />
          <ResourceMenuItem
            href="/contact"
            icon={MailIcon}
            title="Contact"
            description="Talk with our small team"
          />
        </Menu.Popup>
      </Menu.Positioner>
    </Menu.Portal>
  </Menu.Root>
);

interface ResourceMenuItemProps {
  href: string;
  icon: React.ComponentType<{ className?: string }>;
  title: string;
  description: string;
}

const ResourceMenuItem: React.FC<ResourceMenuItemProps> = ({
  href,
  icon: Icon,
  title,
  description,
}) => (
  <Menu.Item
    render={<Link href={href} />}
    className="group flex cursor-pointer items-start gap-3 rounded-lg px-3 py-2.5 outline-none transition-colors duration-150 hover:bg-stone-100 data-[highlighted]:bg-stone-100"
  >
    <span className="mt-0.5 flex size-8 shrink-0 items-center justify-center rounded-lg border border-stone-200 bg-white text-stone-500 shadow-sm">
      <Icon className="size-4" />
    </span>
    <span>
      <span className="block text-sm font-semibold text-stone-800 group-hover:text-violet-800 group-data-[highlighted]:text-violet-800">
        {title}
      </span>
      <span className="mt-0.5 block text-xs leading-4 text-stone-500">{description}</span>
    </span>
  </Menu.Item>
);

const MobileMenu: React.FC = () => (
  <Menu.Root modal={false}>
    <Menu.Trigger
      aria-label="Open navigation"
      className="flex size-9 items-center justify-center rounded-full border border-stone-300/80 bg-white text-stone-700 shadow-sm outline-none transition-colors duration-150 hover:bg-stone-100 focus-visible:ring-2 focus-visible:ring-violet-400/70 data-[popup-open]:bg-stone-100"
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
          <Menu.Separator className="mx-2 my-2 h-px bg-stone-200" />
          <MobileGroupLabel>Resources</MobileGroupLabel>
          <MobileLink href="/blog">Blog</MobileLink>
          <MobileLink href="/docs/getting-started">Help and documentation</MobileLink>
          <MobileLink href="/contact">Contact</MobileLink>
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
