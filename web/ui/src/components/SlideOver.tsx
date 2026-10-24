import { Dialog } from '@base-ui/react/dialog';
import { useLocation, useNavigate } from '@tanstack/react-router';
import cx from 'clsx';
import React from 'react';
import { Drawer } from 'vaul';
import type {
  ResponsiveStackGap,
  ResponsiveStackJustify,
} from '../primitives/stack-utils';
import { normalizePath, useMediaQuery } from '../lib/utils';
import HStack from '../primitives/HStack';
import Text from '../primitives/Text';
import VStack from '../primitives/VStack';
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

export interface SlideOverBodyProps {
  children: React.ReactNode;
  className?: string;
}

export interface SlideOverFooterProps {
  children: React.ReactNode;
  justify?: ResponsiveStackJustify;
  gap?: ResponsiveStackGap;
  bleedX?: boolean;
  className?: string;
}

type SlideOverComponent = React.FC<SlideOverProps> & {
  Body: typeof SlideOverBody;
  Footer: typeof SlideOverFooter;
};

const sizeClasses = {
  small: `md:w-[24rem]`,
  medium: `md:w-[30rem]`,
  large: `md:w-[38rem]`,
};

const horizontalPaddingClasses = `px-4 @lg/slide:px-6`;

const getParentPath = (path: string): string => {
  const normalizedPath = normalizePath(path);
  const parentPath = normalizedPath.split(`/`).slice(0, -1).join(`/`);

  return parentPath || `/`;
};

const SlideOverRoot: React.FC<SlideOverProps> = ({
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

  const Title = isDesktop ? Dialog.Title : Drawer.Title;
  const content = (
    <OverlayPortalProvider container={overlayPortalContainer}>
      <div className="h-full w-full overflow-hidden rounded-[inherit] @container/slide">
        {hasHeading ? (
          <VStack className="h-full">
            <div
              className={cx(
                `shrink-0 pt-6 pb-4 @lg/slide:pt-8`,
                horizontalPaddingClasses,
              )}
            >
              {heading ? (
                <Text as={Title} variant="title">
                  {heading}
                </Text>
              ) : (
                <Title className="sr-only">{ariaLabel}</Title>
              )}
              {subheading && (
                <Text as="p" variant="body" className="mt-1">
                  {subheading}
                </Text>
              )}
            </div>
            <div className={cx(`min-h-0 flex-1`, withPx && horizontalPaddingClasses)}>
              {children}
            </div>
          </VStack>
        ) : (
          <>
            <Title className="sr-only">{ariaLabel}</Title>
            {withPx ? (
              <div className={cx(`h-full`, horizontalPaddingClasses)}>{children}</div>
            ) : (
              children
            )}
          </>
        )}
      </div>
    </OverlayPortalProvider>
  );
  const contentClassName = cx(
    `fixed z-50 flex overflow-visible border border-stone-200 bg-stone-50 shadow-2xl shadow-stone-950/20 outline-none`,
    isDesktop
      ? cx(
          `inset-y-0 right-0 h-dvh max-w-[calc(100vw-1rem)] border-y-0 border-r-0`,
          sizeClasses[size],
        )
      : `inset-x-0 bottom-0 h-[calc(100svh-1rem)] rounded-t-[28px] border-b-0`,
    className,
  );
  const backdropClassName = cx(
    `fixed inset-0 z-50 bg-stone-950/25 backdrop-blur-[1px]`,
    overlayClassName,
  );

  if (isDesktop) {
    return (
      <Dialog.Root
        open={resolvedOpen}
        defaultOpen={normalizedPath ? undefined : defaultOpen}
        onOpenChange={(nextOpen, eventDetails) => {
          if (
            !dismissible &&
            !nextOpen &&
            (eventDetails.reason === `outside-press` ||
              eventDetails.reason === `escape-key`)
          ) {
            eventDetails.cancel();
            return;
          }

          handleOpenChange(nextOpen);
        }}
        disablePointerDismissal={!dismissible}
      >
        {triggerElement ? (
          <Dialog.Trigger render={triggerElement} />
        ) : trigger ? (
          <Dialog.Trigger>{trigger}</Dialog.Trigger>
        ) : null}
        <Dialog.Portal>
          <Dialog.Backdrop
            className={cx(
              backdropClassName,
              `transition-opacity duration-500 data-[starting-style]:opacity-0 data-[ending-style]:opacity-0`,
            )}
          />
          <Dialog.Popup
            ref={setContentRef}
            aria-describedby={undefined}
            className={cx(
              contentClassName,
              `transition-transform duration-500 ease-[cubic-bezier(0.32,0.72,0,1)] data-[starting-style]:translate-x-full data-[ending-style]:translate-x-full`,
            )}
          >
            {content}
          </Dialog.Popup>
        </Dialog.Portal>
      </Dialog.Root>
    );
  }

  return (
    <Drawer.Root
      open={resolvedOpen}
      defaultOpen={normalizedPath ? undefined : defaultOpen}
      onOpenChange={handleOpenChange}
      dismissible={dismissible}
      direction="bottom"
      autoFocus
    >
      {triggerElement ? (
        <Drawer.Trigger asChild>{triggerElement}</Drawer.Trigger>
      ) : trigger ? (
        <Drawer.Trigger>{trigger}</Drawer.Trigger>
      ) : null}
      <Drawer.Portal>
        <Drawer.Overlay className={backdropClassName} />
        <Drawer.Content
          ref={setContentRef}
          aria-describedby={undefined}
          className={contentClassName}
        >
          {content}
        </Drawer.Content>
      </Drawer.Portal>
    </Drawer.Root>
  );
};

const SlideOverBody: React.FC<SlideOverBodyProps> = ({ children, className }) => (
  <div className={cx(`min-h-0 flex-1 overflow-y-auto pb-6`, className)}>{children}</div>
);

const SlideOverFooter: React.FC<SlideOverFooterProps> = ({
  children,
  justify = `between`,
  gap = 3,
  bleedX,
  className,
}) => (
  <HStack
    justify={justify}
    gap={gap}
    className={cx(
      `shrink-0 border-t border-stone-200 bg-stone-50/95 py-3 @lg/slide:py-4`,
      bleedX ? `-mx-4 px-4 @lg/slide:-mx-6 @lg/slide:px-6` : `px-3 @lg/slide:px-6`,
      className,
    )}
  >
    {children}
  </HStack>
);

const SlideOver = Object.assign(SlideOverRoot, {
  Body: SlideOverBody,
  Footer: SlideOverFooter,
}) as SlideOverComponent;

export default SlideOver;
