import { useLocation, useNavigate } from '@tanstack/react-router';
import cx from 'clsx';
import React from 'react';
import { Drawer } from 'vaul';
import { OverlayPortalProvider } from './OverlayPortalContext';

export interface SlideOverProps {
  children: React.ReactNode;
  trigger?: React.ReactNode;
  open?: boolean;
  defaultOpen?: boolean;
  onOpenChange?: (open: boolean) => void;
  path?: string;
  closeTo?: string;
  size?: `small` | `medium` | `large`;
  dismissible?: boolean;
  ariaLabel?: string;
  heading?: React.ReactNode;
  subheading?: React.ReactNode;
  withPx?: boolean;
  className?: string;
  overlayClassName?: string;
}

const useMediaQuery = (query: string): boolean => {
  const [matches, setMatches] = React.useState(false);

  React.useEffect(() => {
    const mediaQueryList = window.matchMedia(query);
    const updateMatches = (): void => setMatches(mediaQueryList.matches);

    updateMatches();
    mediaQueryList.addEventListener(`change`, updateMatches);

    return () => mediaQueryList.removeEventListener(`change`, updateMatches);
  }, [query]);

  return matches;
};

const sizeClasses = {
  small: `md:w-[24rem]`,
  medium: `md:w-[30rem]`,
  large: `md:w-[38rem]`,
};

const horizontalPaddingClasses = `px-4 @lg/slide:px-6`;

const normalizePath = (path: string): string => {
  const withLeadingSlash = path.startsWith(`/`) ? path : `/${path}`;
  return withLeadingSlash === `/`
    ? withLeadingSlash
    : withLeadingSlash.replace(/\/+$/, ``);
};

const getParentPath = (path: string): string => {
  const normalizedPath = normalizePath(path);
  const parentPath = normalizedPath.split(`/`).slice(0, -1).join(`/`);

  return parentPath || `/`;
};

const SlideOver: React.FC<SlideOverProps> = ({
  children,
  trigger,
  open,
  defaultOpen,
  onOpenChange,
  path,
  closeTo,
  size = `medium`,
  dismissible = true,
  ariaLabel = `Slide over panel`,
  heading,
  subheading,
  withPx,
  className,
  overlayClassName,
}) => {
  const isDesktop = useMediaQuery(`(min-width: 768px)`);
  const { pathname } = useLocation();
  const navigate = useNavigate();
  const triggerElement = React.isValidElement(trigger) ? trigger : undefined;
  const normalizedPath = path ? normalizePath(path) : undefined;
  const resolvedCloseTo = normalizedPath
    ? normalizePath(closeTo ?? getParentPath(normalizedPath))
    : undefined;
  const pathOpen = normalizedPath
    ? pathname === normalizedPath || pathname.startsWith(`${normalizedPath}/`)
    : undefined;
  const resolvedOpen = normalizedPath ? pathOpen : open;
  const hasHeading = heading !== undefined || subheading !== undefined;
  const [overlayPortalContainer, setOverlayPortalContainer] =
    React.useState<HTMLElement | null>(null);
  const setContentRef = React.useCallback((node: HTMLDivElement | null) => {
    setOverlayPortalContainer(node);
  }, []);

  const handleOpenChange = (nextOpen: boolean): void => {
    if (normalizedPath && resolvedCloseTo) {
      if (nextOpen && !pathOpen) {
        void navigate({ to: normalizedPath });
      }

      if (!nextOpen && pathOpen) {
        void navigate({ to: resolvedCloseTo });
      }
    }

    onOpenChange?.(nextOpen);
  };

  return (
    <Drawer.Root
      open={resolvedOpen}
      defaultOpen={normalizedPath ? undefined : defaultOpen}
      onOpenChange={handleOpenChange}
      dismissible={dismissible}
      direction={isDesktop ? `right` : `bottom`}
      autoFocus
    >
      {triggerElement ? (
        <Drawer.Trigger asChild>{triggerElement}</Drawer.Trigger>
      ) : trigger ? (
        <Drawer.Trigger>{trigger}</Drawer.Trigger>
      ) : null}
      <Drawer.Portal>
        <Drawer.Overlay
          className={cx(
            `fixed inset-0 z-50 bg-stone-950/25 backdrop-blur-[1px]`,
            overlayClassName,
          )}
        />
        <Drawer.Content
          ref={setContentRef}
          aria-describedby={undefined}
          className={cx(
            `fixed z-50 flex overflow-visible border border-stone-200 bg-stone-50 shadow-2xl shadow-stone-950/20 outline-none`,
            isDesktop
              ? cx(
                  `inset-y-0 right-0 h-dvh max-w-[calc(100vw-1rem)] border-y-0 border-r-0`,
                  sizeClasses[size],
                )
              : `inset-x-0 bottom-0 h-[calc(100svh-1rem)] rounded-t-[28px] border-b-0`,
            className,
          )}
        >
          <OverlayPortalProvider container={overlayPortalContainer}>
            <div className="h-full w-full overflow-hidden rounded-[inherit] @container/slide">
              {hasHeading ? (
                <div className="flex h-full flex-col">
                  <div
                    className={cx(
                      `shrink-0 pt-6 pb-4 @lg/slide:pt-8`,
                      horizontalPaddingClasses,
                    )}
                  >
                    {heading ? (
                      <Drawer.Title className="text-xl font-medium text-stone-900">
                        {heading}
                      </Drawer.Title>
                    ) : (
                      <Drawer.Title className="sr-only">{ariaLabel}</Drawer.Title>
                    )}
                    {subheading && (
                      <p className="mt-2 text-sm text-stone-600">{subheading}</p>
                    )}
                  </div>
                  <div
                    className={cx(`min-h-0 flex-1`, withPx && horizontalPaddingClasses)}
                  >
                    {children}
                  </div>
                </div>
              ) : (
                <>
                  <Drawer.Title className="sr-only">{ariaLabel}</Drawer.Title>
                  {withPx ? (
                    <div className={cx(`h-full`, horizontalPaddingClasses)}>
                      {children}
                    </div>
                  ) : (
                    children
                  )}
                </>
              )}
            </div>
          </OverlayPortalProvider>
        </Drawer.Content>
      </Drawer.Portal>
    </Drawer.Root>
  );
};

export default SlideOver;
