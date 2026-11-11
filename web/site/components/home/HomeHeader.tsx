'use client';

import { ArrowRightIcon, ChevronDownIcon } from 'lucide-react';
import Link from 'next/link';
import React from 'react';
import Logo from '@/components/Logo';
import HomeButtonLink from '@/components/home/HomeButtonLink';
import { homeProducts } from '@/lib/home-products';
import { PARENTS_APP_URL } from '@/lib/urls';

const HomeHeader: React.FC = () => {
  const [isScrolled, setIsScrolled] = React.useState(false);
  const [isDark, setIsDark] = React.useState(false);
  const [productsOpen, setProductsOpen] = React.useState(false);
  const [mobileOpen, setMobileOpen] = React.useState(false);
  const [productHighlight, setProductHighlight] = React.useState({
    index: 0,
    visible: false,
    animate: false,
  });
  const barRef = React.useRef<HTMLDivElement>(null);
  const headerRef = React.useRef<HTMLElement>(null);
  const productsRef = React.useRef<HTMLElement>(null);
  const productsTriggerRef = React.useRef<HTMLButtonElement>(null);
  const mobileRef = React.useRef<HTMLElement>(null);
  const mobileTriggerRef = React.useRef<HTMLButtonElement>(null);
  const productsCloseTimerRef = React.useRef<number | undefined>(undefined);
  const productsPointerTypeRef = React.useRef(``);
  const navigationOpen = productsOpen || mobileOpen;
  const [productVisualsRequested, setProductVisualsRequested] = React.useState(false);
  const [mobileVisualsRequested, setMobileVisualsRequested] = React.useState(false);
  const requestProductVisuals = React.useCallback(
    () => setProductVisualsRequested(true),
    [],
  );
  const requestMobileVisuals = React.useCallback(
    () => setMobileVisualsRequested(true),
    [],
  );

  React.useEffect(() => {
    if (productsOpen) setProductVisualsRequested(true);
  }, [productsOpen]);

  React.useEffect(() => {
    if (mobileOpen) setMobileVisualsRequested(true);
  }, [mobileOpen]);

  const closeProducts = React.useCallback(() => {
    window.clearTimeout(productsCloseTimerRef.current);
    setProductsOpen(false);
    setProductHighlight((highlight) =>
      highlight.visible || highlight.animate
        ? { ...highlight, visible: false, animate: false }
        : highlight,
    );
  }, []);

  React.useEffect(() => {
    const updateScrollState = (): void => {
      setIsScrolled(window.scrollY > 8);
      if (window.innerWidth < 900) closeProducts();
      else setMobileOpen(false);
      const headerBounds = barRef.current?.getBoundingClientRect();
      const headerMidpoint = headerBounds
        ? headerBounds.top + headerBounds.height / 2
        : 0;
      const darkSections = document.querySelectorAll<HTMLElement>(
        `[data-home-header-theme="dark"], [data-home-header-theme="dark-static"]`,
      );
      setIsDark(
        Array.from(darkSections).some((section) => {
          const bounds = section.getBoundingClientRect();
          return section.dataset[`homeHeaderTheme`] === `dark-static`
            ? bounds.top <= headerMidpoint && bounds.bottom >= headerMidpoint
            : bounds.top <= 0 && bounds.bottom >= window.innerHeight;
        }),
      );
    };

    updateScrollState();
    window.addEventListener(`scroll`, updateScrollState, { passive: true });
    window.addEventListener(`resize`, updateScrollState);
    return () => {
      window.removeEventListener(`scroll`, updateScrollState);
      window.removeEventListener(`resize`, updateScrollState);
      window.clearTimeout(productsCloseTimerRef.current);
    };
  }, [closeProducts]);

  React.useEffect(() => {
    if (!productsOpen) return;

    const closeOutside = (event: Event): void => {
      if (
        event.target instanceof Node &&
        !productsTriggerRef.current?.contains(event.target) &&
        !productsRef.current?.contains(event.target)
      ) {
        closeProducts();
      }
    };
    const closeOnEscape = (event: KeyboardEvent): void => {
      if (event.key !== `Escape`) return;
      event.preventDefault();
      closeProducts();
      productsTriggerRef.current?.focus();
    };

    document.addEventListener(`pointerdown`, closeOutside);
    document.addEventListener(`focusin`, closeOutside);
    document.addEventListener(`keydown`, closeOnEscape);
    return () => {
      document.removeEventListener(`pointerdown`, closeOutside);
      document.removeEventListener(`focusin`, closeOutside);
      document.removeEventListener(`keydown`, closeOnEscape);
    };
  }, [productsOpen, closeProducts]);

  React.useEffect(() => {
    if (!mobileOpen) return;

    const previousOverflow = document.documentElement.style.overflow;
    document.documentElement.style.overflow = `hidden`;

    const closeOutside = (event: Event): void => {
      if (event.target instanceof Node && !headerRef.current?.contains(event.target)) {
        setMobileOpen(false);
      }
    };
    const closeOnEscape = (event: KeyboardEvent): void => {
      if (event.key !== `Escape`) return;
      event.preventDefault();
      setMobileOpen(false);
      mobileTriggerRef.current?.focus();
    };

    document.addEventListener(`pointerdown`, closeOutside);
    document.addEventListener(`focusin`, closeOutside);
    document.addEventListener(`keydown`, closeOnEscape);
    return () => {
      document.documentElement.style.overflow = previousOverflow;
      document.removeEventListener(`pointerdown`, closeOutside);
      document.removeEventListener(`focusin`, closeOutside);
      document.removeEventListener(`keydown`, closeOnEscape);
    };
  }, [mobileOpen]);

  const focusFirstProduct = (): void => {
    window.clearTimeout(productsCloseTimerRef.current);
    requestAnimationFrame(() => {
      productsRef.current?.querySelector(`a`)?.focus({ preventScroll: true });
    });
  };

  const scheduleProductsClose = (event: React.PointerEvent<HTMLElement>): void => {
    if (
      event.pointerType === `touch` ||
      productsRef.current?.contains(document.activeElement)
    ) {
      return;
    }
    window.clearTimeout(productsCloseTimerRef.current);
    productsCloseTimerRef.current = window.setTimeout(closeProducts, 150);
  };

  const productRevealClasses = `transition-[opacity,filter,transform] ease-out motion-reduce:transform-none motion-reduce:transition-none ${productsOpen ? `translate-y-0 opacity-100 blur-none duration-[400ms]` : `translate-y-3 opacity-0 blur-[4px] duration-150`}`;

  return (
    <>
      <div
        aria-hidden="true"
        className={`fixed inset-0 z-40 bg-stone-950/30 backdrop-blur-md transition-opacity duration-200 motion-reduce:transition-none ${navigationOpen ? `opacity-100` : `pointer-events-none opacity-0`}`}
      />
      <header
        ref={headerRef}
        onClick={(event) => {
          if (event.target instanceof Element && event.target.closest(`a`)) {
            closeProducts();
            setMobileOpen(false);
          }
        }}
        className={`sticky top-0 z-50 h-[4.5rem] transition-colors duration-300 ${
          isDark ? `text-stone-100` : `text-stone-800`
        }`}
      >
        <div
          className={`relative mx-auto border transition-[width,max-width,border-radius,background-color,border-color,box-shadow,transform] duration-300 ease-[cubic-bezier(0.22,1,0.36,1)] motion-reduce:transition-none ${
            isScrolled
              ? `w-[calc(100%_-_1rem)] max-w-7xl translate-y-2 sm:w-[calc(100%_-_2rem)] md:w-[calc(100%_-_3rem)] lg:w-[calc(100%_-_4rem)] xl:w-[calc(100%_-_6rem)]`
              : `w-full max-w-[84rem]`
          } ${
            isScrolled
              ? navigationOpen
                ? `rounded-[1.75rem]`
                : `rounded-[1.875rem]`
              : navigationOpen
                ? `rounded-b-[1.75rem] rounded-t-none`
                : `rounded-b-[2.25rem] rounded-t-none`
          } ${
            navigationOpen
              ? isDark
                ? `border-white/10 bg-stone-950 shadow-lg shadow-black/25`
                : `border-stone-200/90 bg-white shadow-lg shadow-stone-300/30`
              : isScrolled
                ? isDark
                  ? `border-white/10 bg-stone-950/90 shadow-lg shadow-black/25 backdrop-blur-xl`
                  : `border-stone-200/90 bg-white/90 shadow-lg shadow-stone-300/30 backdrop-blur-xl`
                : `border-transparent`
          }`}
        >
          <div
            ref={barRef}
            className={`relative flex items-center justify-between transition-[height,padding] duration-300 ease-[cubic-bezier(0.22,1,0.36,1)] motion-reduce:transition-none ${
              isScrolled ? `h-[58px] px-[11px]` : `h-[70px] px-4 xs:px-6 lg:px-8`
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
              className="absolute left-1/2 hidden -translate-x-1/2 items-center gap-0.5 md+:flex"
            >
              <button
                ref={productsTriggerRef}
                type="button"
                aria-expanded={productsOpen}
                aria-controls="home-products"
                data-popup-open={productsOpen ? `` : undefined}
                className={`${navItemClasses(isDark)} gap-1.5`}
                onPointerEnter={(event) => {
                  if (event.pointerType === `touch`) return;
                  window.clearTimeout(productsCloseTimerRef.current);
                  setProductsOpen(true);
                }}
                onPointerLeave={scheduleProductsClose}
                onPointerDown={(event) => {
                  productsPointerTypeRef.current = event.pointerType;
                  requestProductVisuals();
                }}
                onFocus={requestProductVisuals}
                onClick={(event) => {
                  if (event.detail === 0) {
                    setProductsOpen(true);
                    focusFirstProduct();
                  } else if (
                    productsPointerTypeRef.current !== `mouse` ||
                    window.matchMedia(`(hover: none)`).matches
                  ) {
                    if (productsOpen) closeProducts();
                    else setProductsOpen(true);
                  }
                }}
                onKeyDown={(event) => {
                  if (event.key !== `ArrowDown`) return;
                  event.preventDefault();
                  setProductsOpen(true);
                  focusFirstProduct();
                }}
              >
                Products
                <ChevronDownIcon
                  aria-hidden="true"
                  className={`size-3.5 transition-transform duration-200 motion-reduce:transition-none ${productsOpen ? `rotate-180` : ``}`}
                />
              </button>
              <NavLink href="/resources" isDark={isDark}>
                Resources
              </NavLink>
              <NavLink href="/#pricing" isDark={isDark}>
                Pricing
              </NavLink>
              <NavLink href="/contact" isDark={isDark}>
                Contact
              </NavLink>
            </nav>

            <div className="hidden items-center gap-2 md+:flex">
              <HomeButtonLink
                href={PARENTS_APP_URL}
                variant="secondary"
                inverted={isDark}
              >
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

            <div className="flex items-center gap-2 md+:hidden">
              <HomeButtonLink
                href={`${PARENTS_APP_URL}/signup?v=new_site`}
                variant="primary"
                inverted={isDark}
                className="hidden xs:inline-flex"
              >
                Get started
              </HomeButtonLink>
              <button
                ref={mobileTriggerRef}
                type="button"
                aria-label={mobileOpen ? `Close navigation` : `Open navigation`}
                aria-expanded={mobileOpen}
                aria-controls="home-mobile-navigation"
                onPointerDown={requestMobileVisuals}
                onFocus={requestMobileVisuals}
                onClick={() => setMobileOpen((open) => !open)}
                onKeyDown={(event) => {
                  if (event.key !== `ArrowDown`) return;
                  event.preventDefault();
                  setMobileOpen(true);
                  requestAnimationFrame(() => {
                    mobileRef.current?.querySelector(`a`)?.focus({ preventScroll: true });
                  });
                }}
                className={`flex size-11 items-center justify-center rounded-full border shadow-sm outline-none transition-colors duration-150 focus-visible:ring-2 focus-visible:ring-violet-400/70 ${
                  isDark
                    ? `border-white/15 bg-white/10 text-stone-100 hover:bg-white/15`
                    : `border-stone-300/80 bg-white text-stone-700 hover:bg-stone-100`
                }`}
              >
                <span aria-hidden="true" className="relative size-5">
                  <span
                    className={`absolute left-0 top-1/2 h-[1.5px] w-5 rounded-full bg-current transition-transform duration-300 ease-[cubic-bezier(0.22,1,0.36,1)] motion-reduce:transition-none ${mobileOpen ? `-translate-y-1/2 rotate-45` : `-translate-y-[4.75px]`}`}
                  />
                  <span
                    className={`absolute left-0 top-1/2 h-[1.5px] w-5 rounded-full bg-current transition-transform duration-300 ease-[cubic-bezier(0.22,1,0.36,1)] motion-reduce:transition-none ${mobileOpen ? `-translate-y-1/2 -rotate-45` : `translate-y-[3.25px]`}`}
                  />
                </span>
              </button>
            </div>
          </div>
          <div
            aria-hidden={!productsOpen}
            inert={!productsOpen}
            className={`hidden transition-[grid-template-rows,opacity] duration-300 ease-[cubic-bezier(0.22,1,0.36,1)] motion-reduce:transition-none md+:grid ${productsOpen ? `grid-rows-[1fr] opacity-100` : `grid-rows-[0fr] opacity-0`}`}
          >
            <div className="min-h-0 overflow-hidden">
              <nav
                ref={productsRef}
                onPointerEnter={() => {
                  window.clearTimeout(productsCloseTimerRef.current);
                }}
                onPointerLeave={scheduleProductsClose}
                id="home-products"
                aria-label="Products"
                className={`border-t px-8 pb-8 pt-6 ${isDark ? `border-white/10` : `border-stone-200/80`}`}
              >
                <div
                  className="relative"
                  onPointerLeave={() => {
                    setProductHighlight((highlight) => ({
                      ...highlight,
                      visible: false,
                    }));
                  }}
                  onBlur={(event) => {
                    if (!event.currentTarget.contains(event.relatedTarget)) {
                      setProductHighlight((highlight) => ({
                        ...highlight,
                        visible: false,
                      }));
                    }
                  }}
                >
                  <div
                    aria-hidden="true"
                    className={`pointer-events-none absolute inset-y-0 left-0 w-[calc((100%_-_6rem)/4)] duration-200 ease-[cubic-bezier(0.22,1,0.36,1)] motion-reduce:transition-none ${productHighlight.animate ? `transition-[transform,opacity]` : `transition-opacity`} ${productsOpen && productHighlight.visible ? `opacity-100` : `opacity-0`}`}
                    style={{
                      transform: `translateX(calc(${productHighlight.index * 100}% + ${productHighlight.index * 2}rem))`,
                    }}
                  >
                    <div
                      className={`absolute -inset-3 rounded-xl ${isDark ? `bg-stone-900` : `bg-stone-100`}`}
                    />
                  </div>
                  <ul className="relative grid grid-cols-4 gap-8">
                    {products.map((product, index) => (
                      <li key={product.href}>
                        <Link
                          href={product.href}
                          onPointerEnter={() => {
                            setProductHighlight((highlight) => ({
                              index,
                              visible: true,
                              animate: highlight.visible,
                            }));
                          }}
                          onFocus={() => {
                            setProductHighlight((highlight) => ({
                              index,
                              visible: true,
                              animate: highlight.visible,
                            }));
                          }}
                          className="group block h-full rounded-lg outline-none focus-visible:ring-2 focus-visible:ring-violet-400/70 focus-visible:ring-offset-4 focus-visible:ring-offset-transparent"
                        >
                          <ProductVisual
                            src={product.visualSrc}
                            load={productVisualsRequested}
                            sizes="300px"
                            className={`mb-3 h-auto w-full ${productRevealClasses}`}
                            style={{
                              transitionDelay: productsOpen
                                ? `${75 + index * 100}ms`
                                : `0ms`,
                            }}
                          />
                          <span
                            className={`block ${productRevealClasses}`}
                            style={{
                              transitionDelay: productsOpen
                                ? `${75 + index * 100 + 60}ms`
                                : `0ms`,
                            }}
                          >
                            <span
                              className={`text-base font-medium tracking-[-0.02em] transition-colors duration-150 ${isDark ? `text-stone-100 group-hover:text-violet-300` : `text-stone-950 group-hover:text-violet-700`}`}
                            >
                              {product.title}
                            </span>
                          </span>
                          <span
                            className={`mt-1 block max-w-56 text-xs leading-[18px] ${productRevealClasses} ${isDark ? `text-stone-400` : `text-stone-800`}`}
                            style={{
                              transitionDelay: productsOpen
                                ? `${75 + index * 100 + 120}ms`
                                : `0ms`,
                            }}
                          >
                            {product.description}
                          </span>
                        </Link>
                      </li>
                    ))}
                  </ul>
                </div>
              </nav>
            </div>
          </div>
          <MobileMenu
            open={mobileOpen}
            isDark={isDark}
            navRef={mobileRef}
            loadVisuals={mobileVisualsRequested}
          />
        </div>
      </header>
    </>
  );
};

export default HomeHeader;

const navItemClasses = (isDark: boolean): string =>
  `inline-flex h-9 items-center rounded-full px-3 text-sm font-[450] outline-none transition-colors duration-150 focus-visible:ring-2 focus-visible:ring-violet-400/70 ${
    isDark
      ? `text-stone-300 hover:bg-white/10 hover:text-white data-[popup-open]:bg-white/10 data-[popup-open]:text-white`
      : `text-stone-600 hover:bg-stone-100 hover:text-stone-950 data-[popup-open]:bg-stone-100 data-[popup-open]:text-stone-950`
  }`;

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

const products = Object.values(homeProducts);

interface ProductVisualProps {
  src: string;
  load: boolean;
  sizes: string;
  className?: string;
  style?: React.CSSProperties;
}

const ProductVisual: React.FC<ProductVisualProps> = ({
  src,
  load,
  sizes,
  className = ``,
  style,
}) => {
  const image = {
    src: src.replace(/\.webp$/, `-600.webp`),
    srcSet: [240, 600]
      .map((w) => `${src.replace(/\.webp$/, `-${w}.webp`)} ${w}w`)
      .join(`, `),
    sizes,
    width: 1200,
    height: 820,
  };
  return (
    <div className={`relative aspect-[1200/820] ${className}`} style={style}>
      {load && (
        <>
          <img
            {...image}
            alt=""
            className="absolute inset-0 rounded-lg blur-sm opacity-50"
          />
          <img {...image} alt="" className="relative h-full w-full rounded-lg" />
        </>
      )}
      <div className="pointer-events-none absolute inset-0 rounded-lg border border-black/10" />
    </div>
  );
};

interface MobileMenuProps {
  open: boolean;
  isDark: boolean;
  navRef: React.RefObject<HTMLElement | null>;
  loadVisuals: boolean;
}

const MobileMenu: React.FC<MobileMenuProps> = ({ open, isDark, navRef, loadVisuals }) => (
  <div
    aria-hidden={!open}
    inert={!open}
    className={`grid transition-[grid-template-rows,opacity] duration-300 ease-[cubic-bezier(0.22,1,0.36,1)] motion-reduce:transition-none md+:hidden ${open ? `grid-rows-[1fr] opacity-100` : `grid-rows-[0fr] opacity-0`}`}
  >
    <div className="min-h-0 overflow-hidden">
      <nav
        ref={navRef}
        id="home-mobile-navigation"
        aria-label="Mobile navigation"
        className={`max-h-[calc(100dvh-5.5rem)] overflow-y-auto overscroll-contain rounded-b-[1.75rem] border-t p-4 xs:p-6 sm:p-8 ${isDark ? `border-white/10` : `border-stone-200/80`}`}
      >
        <ul className="grid gap-1 sm:grid-cols-2 sm:gap-3">
          {products.map((product, index) => (
            <li
              key={product.href}
              className={`transition-[opacity,filter,transform] duration-300 motion-reduce:transform-none motion-reduce:transition-none ${open ? `translate-y-0 opacity-100 blur-none` : `translate-y-2 opacity-0 blur-[3px]`}`}
              style={{ transitionDelay: open ? `${60 + index * 45}ms` : `0ms` }}
            >
              <Link
                href={product.href}
                className={`-mx-2 flex h-full items-center gap-4 rounded-xl p-2 outline-none transition-colors duration-150 focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-violet-400/70 ${isDark ? `hover:bg-white/5` : `hover:bg-stone-100`}`}
              >
                <ProductVisual
                  src={product.visualSrc}
                  load={loadVisuals}
                  sizes="80px"
                  className="w-20 shrink-0"
                />
                <span className="min-w-0">
                  <span
                    className={`block text-base font-medium tracking-[-0.02em] ${isDark ? `text-stone-100` : `text-stone-950`}`}
                  >
                    {product.title}
                  </span>
                  <span
                    className={`mt-1 block text-xs leading-[18px] ${isDark ? `text-stone-400` : `text-stone-600`}`}
                  >
                    {product.description}
                  </span>
                </span>
              </Link>
            </li>
          ))}
        </ul>
        <div className="mt-4 flex gap-2 py-2">
          <MobileLink href="/resources" isDark={isDark}>
            Resources
          </MobileLink>
          <MobileLink href="/#pricing" isDark={isDark}>
            Pricing
          </MobileLink>
          <MobileLink href="/contact" isDark={isDark}>
            Contact
          </MobileLink>
        </div>
        <div className="grid grid-cols-[1fr_2fr] gap-3 pt-4 xs:grid-cols-2">
          <HomeButtonLink
            href={PARENTS_APP_URL}
            size="hero"
            variant="secondary"
            inverted={isDark}
          >
            Log in
          </HomeButtonLink>
          <HomeButtonLink
            href={`${PARENTS_APP_URL}/signup?v=new_site`}
            size="hero"
            variant="primary"
            inverted={isDark}
          >
            Get started free
          </HomeButtonLink>
        </div>
      </nav>
    </div>
  </div>
);

const MobileLink: React.FC<ThemeAwareLinkProps> = ({ href, isDark, children }) => (
  <Link
    href={href}
    className={`inline-flex min-h-11 flex-1 items-center justify-center rounded-full px-2 text-sm font-medium outline-none transition-colors duration-150 focus-visible:ring-2 focus-visible:ring-violet-400/70 ${isDark ? `text-stone-300 hover:bg-white/5 hover:text-white` : `text-stone-600 hover:bg-stone-100 hover:text-stone-950`}`}
  >
    {children}
  </Link>
);
