import React from 'react';
import * as Dialog from '@radix-ui/react-dialog';
import { Drawer } from 'vaul';
import cx from 'clsx';

export interface ModalProps {
  children?: React.ReactNode;
  title: React.ReactNode;
  description?: React.ReactNode;
  footer?: React.ReactNode;
  trigger?: React.ReactNode;
  open?: boolean;
  defaultOpen?: boolean;
  onOpenChange?: (open: boolean) => void;
  size?: 'small' | 'medium' | 'large';
  dismissible?: boolean;
  className?: string;
  bodyClassName?: string;
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
  small: 'md:max-w-md',
  medium: 'md:max-w-lg',
  large: 'md:max-w-2xl',
};

const Modal: React.FC<ModalProps> = ({
  children,
  title,
  description,
  footer,
  trigger,
  open,
  defaultOpen,
  onOpenChange,
  size = 'medium',
  dismissible = true,
  className,
  bodyClassName,
}) => {
  const isDesktop = useMediaQuery('(min-width: 768px)');
  const hasBody = children !== undefined && children !== null && children !== false;

  if (isDesktop) {
    return (
      <Dialog.Root open={open} defaultOpen={defaultOpen} onOpenChange={onOpenChange}>
        {trigger && <Dialog.Trigger asChild>{trigger}</Dialog.Trigger>}
        <Dialog.Portal>
          <Dialog.Overlay className="fixed inset-0 z-50 bg-stone-950/35 backdrop-blur-[2px]" />
          <Dialog.Content
            className={cx(
              'fixed left-1/2 top-1/2 z-50 flex max-h-[min(82vh,720px)] w-[calc(100vw-2rem)] -translate-x-1/2 -translate-y-1/2 flex-col overflow-hidden rounded-2xl border border-stone-200 bg-white shadow-2xl shadow-stone-950/20 outline-none',
              sizeClasses[size],
              className,
            )}
            onEscapeKeyDown={(event) => {
              if (!dismissible) {
                event.preventDefault();
              }
            }}
            onPointerDownOutside={(event) => {
              if (!dismissible) {
                event.preventDefault();
              }
            }}
          >
            <div className="flex flex-col gap-1 px-5 pb-4 pt-5">
              <Dialog.Title className="text-xl font-medium text-stone-950">
                {title}
              </Dialog.Title>
              {description && (
                <Dialog.Description className="text-sm leading-6 text-stone-600">
                  {description}
                </Dialog.Description>
              )}
            </div>
            {hasBody && (
              <div className={cx('overflow-auto px-5 pb-5', bodyClassName)}>
                {children}
              </div>
            )}
            {footer && (
              <div className="flex justify-end gap-2 border-t border-stone-200 bg-stone-50 px-5 py-3">
                {footer}
              </div>
            )}
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>
    );
  }

  return (
    <Drawer.Root
      open={open}
      defaultOpen={defaultOpen}
      onOpenChange={onOpenChange}
      dismissible={dismissible}
    >
      {trigger && <Drawer.Trigger asChild>{trigger}</Drawer.Trigger>}
      <Drawer.Portal>
        <Drawer.Overlay className="fixed inset-0 z-50 bg-stone-950/35 backdrop-blur-[2px]" />
        <Drawer.Content
          className={cx(
            'fixed inset-x-0 bottom-0 z-50 flex max-h-[calc(100svh-1rem)] flex-col overflow-hidden rounded-t-[28px] border border-b-0 border-stone-200 bg-white shadow-2xl shadow-stone-950/20 outline-none',
            className,
          )}
        >
          <Drawer.Handle className="mx-auto mt-3 h-1.5 w-12 rounded-full bg-stone-300" />
          <div className="flex flex-col gap-1 px-5 pb-4 pt-4">
            <Drawer.Title className="text-xl font-medium text-stone-950">
              {title}
            </Drawer.Title>
            {description && (
              <Drawer.Description className="text-sm leading-6 text-stone-600">
                {description}
              </Drawer.Description>
            )}
          </div>
          {hasBody && (
            <div className={cx('overflow-auto px-5 pb-5', bodyClassName)}>
              {children}
            </div>
          )}
          {footer && (
            <div className="flex justify-end gap-2 border-t border-stone-200 bg-stone-50 px-5 py-3 pb-[calc(0.75rem+env(safe-area-inset-bottom))]">
              {footer}
            </div>
          )}
        </Drawer.Content>
      </Drawer.Portal>
    </Drawer.Root>
  );
};

export default Modal;
