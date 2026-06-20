import { Toast } from '@base-ui/react/toast';
import cx from 'clsx';
import { CheckIcon, InfoIcon, type LucideIcon, XIcon } from 'lucide-react';
import React from 'react';
import type { ToastVariant } from './toast';
import LoadingDots from './LoadingDots';
import { toastManager } from './toast';

type VariantStyles = {
  iconContainer: string;
  icon: string;
  Icon: LucideIcon;
};

const variantStyles: Record<Exclude<ToastVariant, `loading`>, VariantStyles> = {
  success: { iconContainer: `bg-emerald-500`, icon: `text-white`, Icon: CheckIcon },
  error: { iconContainer: `bg-red-500`, icon: `text-white`, Icon: XIcon },
  info: { iconContainer: ``, icon: `text-stone-400`, Icon: InfoIcon },
};

const getVariantStyles = (type: string | undefined): VariantStyles =>
  variantStyles[type as Exclude<ToastVariant, `loading`>] ?? variantStyles.info;

const stackClasses = [
  `[--gap:0.75rem]`,
  `[--peek:0.7rem]`,
  `[--scale:calc(max(0,1-(var(--toast-index)*0.08)))]`,
  `[--shrink:calc(1-var(--scale))]`,
  `[--height:var(--toast-frontmost-height,var(--toast-height))]`,
  `[--offset-y:calc(var(--toast-offset-y)*-1+(var(--toast-index)*var(--gap)*-1)+var(--toast-swipe-movement-y))]`,
  `absolute right-0 bottom-0 left-auto z-[calc(1000-var(--toast-index))] w-full origin-bottom select-none`,
  `h-[var(--height)] data-expanded:h-[var(--toast-height)]`,
  `[transform:translateX(var(--toast-swipe-movement-x))_translateY(calc(var(--toast-swipe-movement-y)-(var(--toast-index)*var(--peek))-(var(--shrink)*var(--height))))_scale(var(--scale))]`,
  `data-expanded:[transform:translateX(var(--toast-swipe-movement-x))_translateY(var(--offset-y))]`,
  `[transition:transform_0.5s_cubic-bezier(0.22,1,0.36,1),opacity_0.5s,height_0.15s]`,
  `after:absolute after:top-full after:left-0 after:h-[calc(var(--gap)+1px)] after:w-full after:content-['']`,
  `data-limited:opacity-0`,
  `data-starting-style:[transform:translateY(150%)]`,
  `data-ending-style:opacity-0`,
  `[&[data-ending-style]:not([data-limited]):not([data-swipe-direction])]:[transform:translateY(150%)]`,
  `data-ending-style:data-[swipe-direction=right]:[transform:translateX(calc(var(--toast-swipe-movement-x)+150%))_translateY(var(--offset-y))]`,
  `data-expanded:data-ending-style:data-[swipe-direction=right]:[transform:translateX(calc(var(--toast-swipe-movement-x)+150%))_translateY(var(--offset-y))]`,
].join(` `);

type ToastMessageContent = {
  title?: React.ReactNode;
  description?: React.ReactNode;
};

interface ToastMessageProps extends ToastMessageContent {
  version: number;
}

const PlainToastMessage: React.FC<ToastMessageContent> = ({ title, description }) => (
  <>
    {title ? <div className="m-0 text-sm font-medium">{title}</div> : null}
    {description ? <div className="m-0 text-sm leading-5">{description}</div> : null}
  </>
);

const ToastMessage: React.FC<ToastMessageProps> = ({ title, description, version }) => {
  const [current, setCurrent] = React.useState<ToastMessageContent>(() => ({
    title,
    description,
  }));
  const [outgoing, setOutgoing] = React.useState<ToastMessageContent | null>(null);
  const currentRef = React.useRef(current);
  const previousVersionRef = React.useRef(version);

  React.useLayoutEffect(() => {
    currentRef.current = current;
  }, [current]);

  React.useLayoutEffect(() => {
    const next = { title, description };

    if (previousVersionRef.current === version) {
      currentRef.current = next;
      setCurrent(next);
      return;
    }

    previousVersionRef.current = version;
    setOutgoing(currentRef.current);
    currentRef.current = next;
    setCurrent(next);

    const timeout = window.setTimeout(() => setOutgoing(null), 360);
    return () => window.clearTimeout(timeout);
  }, [description, title, version]);

  const isTransitioning = outgoing !== null;

  return (
    <div className="relative min-w-0 flex-1 overflow-hidden">
      <div className={cx(isTransitioning && `toast-message-in`)} key={version}>
        <Toast.Title className="m-0 text-sm font-medium">{current.title}</Toast.Title>
        <Toast.Description className="m-0 text-sm leading-5">
          {current.description}
        </Toast.Description>
      </div>
      {outgoing ? (
        <div aria-hidden="true" className="toast-message-out absolute inset-x-0 top-0">
          <PlainToastMessage {...outgoing} />
        </div>
      ) : null}
    </div>
  );
};

const Toaster: React.FC = () => (
  <Toast.Provider toastManager={toastManager} timeout={5000} limit={3}>
    <Toast.Portal>
      <Toast.Viewport className="fixed top-auto right-4 bottom-4 left-auto z-[80] w-[calc(100vw-2rem)] outline-none sm:right-6 sm:bottom-6 sm:w-96">
        <ToastList />
      </Toast.Viewport>
    </Toast.Portal>
  </Toast.Provider>
);

const ToastList: React.FC = () => {
  const { toasts } = Toast.useToastManager();

  return toasts.map((toast) => {
    const isLoading = toast.type === `loading`;
    const styles = getVariantStyles(toast.type);
    const Icon = styles.Icon;

    return (
      <Toast.Root
        key={toast.id}
        toast={toast}
        swipeDirection="right"
        className={cx(
          stackClasses,
          `cursor-default rounded-xl border border-stone-200 bg-white text-stone-950 shadow-lg shadow-stone-950/10 outline-none focus-visible:ring-2 focus-visible:ring-stone-400/70`,
        )}
      >
        <Toast.Content className="flex h-full items-center justify-between gap-3 overflow-hidden px-3 py-2.5 transition-opacity duration-[250ms] ease-[cubic-bezier(0.22,1,0.36,1)] data-behind:opacity-0 data-expanded:opacity-100">
          <span className="relative flex h-5 w-5 shrink-0 items-center justify-center">
            <span
              aria-hidden={!isLoading}
              className={cx(
                `absolute inset-0 flex origin-center items-center justify-center transition-[scale,filter] duration-[420ms] ease-[cubic-bezier(0.22,1,0.36,1)]`,
                isLoading ? `scale-100 blur-0` : `scale-0 blur-[2px]`,
              )}
            >
              <LoadingDots size="small" />
            </span>
            <span
              aria-hidden="true"
              className={cx(
                `absolute inset-0 flex origin-center items-center justify-center rounded-full transition-[scale,filter] duration-[420ms] ease-[cubic-bezier(0.22,1,0.36,1)]`,
                styles.iconContainer,
                isLoading ? `scale-0 blur-[2px]` : `scale-100 blur-0`,
              )}
            >
              <Icon className={cx(`h-3.5 w-3.5`, styles.icon)} strokeWidth={3} />
            </span>
          </span>
          <ToastMessage
            title={toast.title}
            description={toast.description}
            version={toast.updateKey ?? 0}
          />
        </Toast.Content>
      </Toast.Root>
    );
  });
};

export default Toaster;
