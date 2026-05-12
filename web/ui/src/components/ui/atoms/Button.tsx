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

const Button: React.FC<Props> = (props) => {
  const isDisabled = props.disabled || props.loading;
  const iconPosition = props.iconPosition ?? 'left';
  const hasLabel = props.children !== undefined && props.children !== null && props.children !== '';
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
    'h-5 w-5': props.size === 'large',
  });
  const iconSlotSizeClasses = cx({
    'h-3': props.size === 'small',
    'h-4': props.size === 'medium' || props.size === undefined,
    'h-5': props.size === 'large',
  });
  const iconSlotWidthClasses = cx({
    'w-3': props.size === 'small',
    'w-4': props.size === 'medium' || props.size === undefined,
    'w-5': props.size === 'large',
  });
  const iconSlotGapClasses = cx({
    'mr-[5px]': hasLabel && iconPosition === 'left' && props.size === 'small',
    'mr-1.5':
      hasLabel &&
      iconPosition === 'left' &&
      (props.size === 'medium' || props.size === undefined),
    'mr-2': hasLabel && iconPosition === 'left' && props.size === 'large',
    'ml-[5px]': hasLabel && iconPosition === 'right' && props.size === 'small',
    'ml-1.5':
      hasLabel &&
      iconPosition === 'right' &&
      (props.size === 'medium' || props.size === undefined),
    'ml-2': hasLabel && iconPosition === 'right' && props.size === 'large',
  });
  const innerClasses = cx(
    'flex items-center justify-center font-[450]',
    {
      'bg-violet-500 text-white': props.variant === 'primary',
      'bg-white text-stone-800':
        props.variant === 'default' || props.variant === undefined,
      'bg-none text-stone-600': props.variant === 'ghost',
      'bg-white/70 text-red-900/80': props.variant === 'destructive',
    },
    hasLabel
      ? {
          'rounded-md px-1.5 py-0.5 text-xs': props.size === 'small',
          'rounded-lg px-2 py-1 text-sm':
            props.size === 'medium' || props.size === undefined,
          'rounded-xl px-3 py-2': props.size === 'large',
        }
      : {
          'rounded-md p-1': props.size === 'small',
          'rounded-lg p-1.5': props.size === 'medium' || props.size === undefined,
          'rounded-xl p-2': props.size === 'large',
        },
  );
  const outerClasses = cx(
    'p-[1px] outline-none transition-[background-color,box-shadow,opacity] duration-150 focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-offset-stone-50',
    isDisabled ? 'cursor-not-allowed opacity-50' : 'cursor-pointer',
    {
      'bg-violet-800 shadow-violet-500/30 focus-visible:ring-violet-400/70':
        props.variant === 'primary',
      'bg-stone-300/80 shadow-stone-300/30 focus-visible:ring-stone-400/70':
        props.variant === 'default' || props.variant === undefined,
      'bg-none shadow-transparent focus-visible:ring-stone-400/70':
        props.variant === 'ghost',
      'bg-red-600/30 shadow-red-700/10 focus-visible:ring-red-400/70':
        props.variant === 'destructive',
    },
    !isDisabled && {
      'hover:bg-violet-900 hover:shadow-violet-500/50': props.variant === 'primary',
      'hover:bg-stone-400/70 hover:shadow-stone-300/80':
        props.variant === 'default' || props.variant === undefined,
      'hover:bg-stone-200/70': props.variant === 'ghost',
      'hover:bg-red-600/50': props.variant === 'destructive',
    },
    {
      'rounded-[7px] shadow': props.size === 'small',
      'rounded-[9px] shadow': props.size === 'medium' || props.size === undefined,
      'rounded-[13px] shadow': props.size === 'large',
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
                props.loading ? 'scale-0 opacity-0 blur-[1px]' : 'scale-100 opacity-100 blur-none',
            )}
            aria-hidden="true"
          />
        )}
        <LoaderCircleIcon
          className={cx(
            'absolute animate-spin transition-[opacity,transform,filter] duration-[400ms] ease-out',
            iconClasses,
            props.loading ? 'scale-100 opacity-100 blur-none' : 'scale-0 opacity-0 blur-[1px]',
          )}
          aria-hidden="true"
        />
      </span>
    );
  };

  const content = (
    <span className={innerClasses}>
      {iconPosition === 'left' && iconSlot()}
      {hasLabel && <span>{props.children}</span>}
      {iconPosition === 'right' && iconSlot()}
    </span>
  );

  switch (props.type) {
    case 'button':
      return (
        <button
          type="button"
          className={outerClasses}
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
          className={outerClasses}
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
          className={outerClasses}
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
};

export default Button;
