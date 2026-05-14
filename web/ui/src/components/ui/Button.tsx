import React from 'react';
import { LoaderCircleIcon, type LucideIcon } from 'lucide-react';
import cx from 'clsx';

type CommonProps = {
  children?: React.ReactNode;
  ariaLabel?: string;
  icon?: LucideIcon;
  iconPosition?: 'left' | 'right';
  variant?: 'primary' | 'default' | 'ghost' | 'destructive';
  size?: 'small' | 'medium' | 'large';
  loading?: boolean;
  disabled?: boolean;
};

type Props = CommonProps &
  (
    | {
        type: 'button';
        onClick: () => void;
      }
    | {
        type: 'submit';
      }
    | {
        type: 'link';
        href: string;
      }
  );

const ownPropKeys = new Set([
  'children',
  'ariaLabel',
  'icon',
  'iconPosition',
  'variant',
  'size',
  'loading',
  'disabled',
  'type',
  'onClick',
  'href',
]);

const getPassThroughProps = (props: Props): React.HTMLAttributes<HTMLElement> => {
  return Object.fromEntries(
    Object.entries(props).filter(([key]) => !ownPropKeys.has(key)),
  ) as React.HTMLAttributes<HTMLElement>;
};

const Button = React.forwardRef<HTMLElement, Props>((props, ref) => {
  const passThroughProps = getPassThroughProps(props);
  const isDisabled = props.disabled || props.loading;
  const iconPosition = props.iconPosition ?? 'left';
  const hasLabel =
    props.children !== undefined && props.children !== null && props.children !== '';
  const [showLoaderSlot, setShowLoaderSlot] = React.useState(false);
  const [loaderSlotOpen, setLoaderSlotOpen] = React.useState(false);

  React.useEffect(() => {
    if (props.loading) {
      setShowLoaderSlot(true);
      const animationFrame = window.requestAnimationFrame(() => setLoaderSlotOpen(true));
      return () => window.cancelAnimationFrame(animationFrame);
    }

    setLoaderSlotOpen(false);
    const timeout = window.setTimeout(() => setShowLoaderSlot(false), 420);
    return () => window.clearTimeout(timeout);
  }, [props.loading]);

  const iconClasses = cx({
    'h-3 w-3': props.size === 'small',
    'h-4 w-4': props.size === 'medium' || props.size === undefined,
    'h-4.5 w-4.5': props.size === 'large',
  });
  const iconSlotSizeClasses = cx({
    'h-[1lh]': !hasLabel,
    'h-3': hasLabel && props.size === 'small',
    'h-4': hasLabel && (props.size === 'medium' || props.size === undefined),
    'h-4.5': hasLabel && props.size === 'large',
  });
  const iconSlotWidthClasses = cx({
    'w-[1lh]': !hasLabel,
    'w-3': hasLabel && props.size === 'small',
    'w-4': hasLabel && (props.size === 'medium' || props.size === undefined),
    'w-4.5': hasLabel && props.size === 'large',
  });
  const iconSlotGapClasses = cx({
    'mr-1.25': hasLabel && iconPosition === 'left' && props.size === 'small',
    'mr-2':
      hasLabel &&
      iconPosition === 'left' &&
      (props.size === 'medium' || props.size === undefined || props.size === 'large'),
    'ml-1.25': hasLabel && iconPosition === 'right' && props.size === 'small',
    'ml-2':
      hasLabel &&
      iconPosition === 'right' &&
      (props.size === 'medium' || props.size === undefined || props.size === 'large'),
  });
  const buttonClasses = cx(
    'inline-flex items-center justify-center border font-[450] shadow outline-none transition-[background-color,border-color,box-shadow,opacity] duration-150 focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-offset-stone-50 select-none',
    isDisabled ? 'cursor-not-allowed opacity-50' : 'cursor-pointer',
    {
      'border-violet-800 bg-violet-500 text-white shadow-violet-500/30 focus-visible:ring-violet-400/70':
        props.variant === 'primary',
      'border-stone-300/80 bg-white text-stone-800 shadow-stone-300/30 focus-visible:ring-stone-400/70':
        props.variant === 'default' || props.variant === undefined,
      'border-transparent bg-transparent text-stone-600 shadow-transparent focus-visible:ring-stone-400/70':
        props.variant === 'ghost',
      'border-red-800/20 bg-red-600/3 text-red-900/80 shadow-red-700/10 focus-visible:ring-red-400/70':
        props.variant === 'destructive',
    },
    !isDisabled && {
      'hover:border-violet-900 hover:shadow-violet-500/50': props.variant === 'primary',
      'hover:border-stone-400/70 hover:shadow-stone-300/80':
        props.variant === 'default' || props.variant === undefined,
      'hover:bg-stone-200/70': props.variant === 'ghost',
      'hover:border-red-600/50': props.variant === 'destructive',
    },
    hasLabel
      ? {
          'rounded-[7px] px-2 py-1 text-[13px]': props.size === 'small',
          'rounded-[9px] px-2.5 py-1.5 text-[15px]':
            props.size === 'medium' || props.size === undefined,
          'rounded-[13px] px-3.5 py-2.75 text-base': props.size === 'large',
        }
      : {
          'rounded-[7px] px-1 py-1 text-[13px]': props.size === 'small',
          'rounded-[9px] px-1.5 py-1.5 text-[15px]':
            props.size === 'medium' || props.size === undefined,
          'rounded-[13px] px-2.75 py-2.75 text-base': props.size === 'large',
        },
  );

  const iconSlot = (): React.ReactNode => {
    const shouldRender = props.icon || props.loading || showLoaderSlot;

    if (!shouldRender) {
      return null;
    }

    const Icon = props.icon;
    const slotOpen = !!props.icon || loaderSlotOpen;

    return (
      <span
        className={cx(
          'relative inline-flex shrink-0 items-center justify-center overflow-hidden transition-[width,margin,opacity,filter] duration-[400ms] ease-out',
          iconSlotSizeClasses,
          slotOpen ? iconSlotWidthClasses : 'w-0 opacity-0 blur-[1px]',
          slotOpen && iconSlotGapClasses,
        )}
      >
        {Icon && (
          <Icon
            className={cx(
              'absolute transition-[opacity,transform,filter] duration-[400ms] ease-out',
              iconClasses,
              props.loading
                ? 'scale-0 opacity-0 blur-[1px]'
                : 'scale-100 opacity-100 blur-none',
            )}
            aria-hidden="true"
          />
        )}
        <LoaderCircleIcon
          className={cx(
            'absolute animate-spin transition-[opacity,transform,filter] duration-[400ms] ease-out',
            iconClasses,
            props.loading
              ? 'scale-100 opacity-100 blur-none'
              : 'scale-0 opacity-0 blur-[1px]',
          )}
          aria-hidden="true"
        />
      </span>
    );
  };

  const content = (
    <>
      {iconPosition === 'left' && iconSlot()}
      {hasLabel && <span>{props.children}</span>}
      {iconPosition === 'right' && iconSlot()}
    </>
  );

  switch (props.type) {
    case 'button':
      return (
        <button
          {...passThroughProps}
          ref={ref as React.Ref<HTMLButtonElement>}
          type="button"
          className={buttonClasses}
          disabled={isDisabled}
          aria-label={props.ariaLabel}
          aria-busy={props.loading ? true : undefined}
          onClick={props.onClick}
        >
          {content}
        </button>
      );
    case 'submit':
      return (
        <button
          {...passThroughProps}
          ref={ref as React.Ref<HTMLButtonElement>}
          className={buttonClasses}
          type="submit"
          disabled={isDisabled}
          aria-label={props.ariaLabel}
          aria-busy={props.loading ? true : undefined}
        >
          {content}
        </button>
      );
    case 'link':
      return (
        <a
          {...passThroughProps}
          ref={ref as React.Ref<HTMLAnchorElement>}
          className={buttonClasses}
          href={props.href}
          aria-label={props.ariaLabel}
          aria-disabled={isDisabled ? true : undefined}
          aria-busy={props.loading ? true : undefined}
          tabIndex={isDisabled ? -1 : undefined}
          onClick={(event) => {
            if (isDisabled) {
              event.preventDefault();
            }
          }}
        >
          {content}
        </a>
      );
  }
});

Button.displayName = 'Button';

export default Button;
