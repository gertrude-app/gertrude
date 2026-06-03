import React from 'react';
import { Drawer } from 'vaul';
import cx from 'clsx';

export interface SlideOverProps {
  children: React.ReactNode;
  trigger?: React.ReactNode;
  open?: boolean;
  defaultOpen?: boolean;
  onOpenChange?: (open: boolean) => void;
  size?: 'small' | 'medium' | 'large';
  dismissible?: boolean;
  ariaLabel?: string;
  className?: string;
  overlayClassName?: string;
}

const useMediaQuery = (query: string): boolean => {
  const [matches, setMatches] = React.useState(false);

  React.useEffect(() => {
    const mediaQueryList = window.matchMedia(query);
    const updateMatches = (): void => setMatches(mediaQueryList.matches);

    updateMatches();
    mediaQueryList.addEventListener('change', updateMatches);

    return () => mediaQueryList.removeEventListener('change', updateMatches);
  }, [query]);

  return matches;
};

const sizeClasses = {
  small: 'md:w-[24rem]',
  medium: 'md:w-[30rem]',
  large: 'md:w-[38rem]',
};

const SlideOver: React.FC<SlideOverProps> = ({
  children,
  trigger,
  open,
  defaultOpen,
  onOpenChange,
  size = 'medium',
  dismissible = true,
  ariaLabel = 'Slide over panel',
  className,
  overlayClassName,
}) => {
  const isDesktop = useMediaQuery('(min-width: 768px)');
  const triggerElement = React.isValidElement(trigger) ? trigger : undefined;

  return (
    <Drawer.Root
      open={open}
      defaultOpen={defaultOpen}
      onOpenChange={onOpenChange}
      dismissible={dismissible}
      direction={isDesktop ? 'right' : 'bottom'}
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
            'fixed inset-0 z-50 bg-stone-950/25 backdrop-blur-[1px]',
            overlayClassName,
          )}
        />
        <Drawer.Content
          aria-describedby={undefined}
          className={cx(
            'fixed z-50 flex overflow-hidden border border-stone-200 bg-stone-50 shadow-2xl shadow-stone-950/20 outline-none',
            isDesktop
              ? cx(
                  'inset-y-0 right-0 h-dvh max-w-[calc(100vw-1rem)] border-y-0 border-r-0',
                  sizeClasses[size],
                )
              : 'inset-x-0 bottom-0 h-[calc(100svh-1rem)] rounded-t-[28px] border-b-0',
            className,
          )}
        >
          <Drawer.Title className="sr-only">{ariaLabel}</Drawer.Title>
          {children}
        </Drawer.Content>
      </Drawer.Portal>
    </Drawer.Root>
  );
};

export default SlideOver;
