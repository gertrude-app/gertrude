import React from 'react';
import { Link } from '@tanstack/react-router';
import { ChevronDownIcon, LoaderCircleIcon, type LucideIcon } from 'lucide-react';
import cx from 'clsx';
import DropdownMenu from './dropdown-menu/DropdownMenu';
import DropdownMenuItem from './dropdown-menu/DropdownMenuItem';

type ButtonVariant = 'primary' | 'default' | 'ghost' | 'destructive';
type ButtonSize = 'small' | 'medium' | 'large';

type DropdownItem = {
  title: string;
  icon?: LucideIcon;
  selected?: boolean;
  onSelect?: () => void;
  children?: React.ReactNode;
};

type CommonProps = {
  children?: React.ReactNode;
  ariaLabel?: string;
  icon?: LucideIcon;
  iconPosition?: 'left' | 'right';
  variant?: ButtonVariant;
  size?: ButtonSize;
  loading?: boolean;
  disabled?: boolean;
  className?: string;
  dropdownItems?: DropdownItem[];
  dropdownAriaLabel?: string;
  dropdownSearchable?: boolean;
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
  'className',
  'dropdownItems',
  'dropdownAriaLabel',
  'dropdownSearchable',
  'type',
  'onClick',
  'href',
]);

const getPassThroughProps = (props: Props): React.HTMLAttributes<HTMLElement> => {
  return Object.fromEntries(
    Object.entries(props).filter(([key]) => !ownPropKeys.has(key)),
  ) as React.HTMLAttributes<HTMLElement>;
};

const getRoundedClasses = (
  size: ButtonSize | undefined,
  splitPart: 'main' | 'dropdown' | undefined,
): string => {
  if (splitPart === 'main') {
    return cx({
      'rounded-l-[7px] rounded-r-none': size === 'small',
      'rounded-l-[9px] rounded-r-none': size === 'medium' || size === undefined,
      'rounded-l-[13px] rounded-r-none': size === 'large',
    });
  }

  if (splitPart === 'dropdown') {
    return cx('-ml-px', {
      'rounded-l-none rounded-r-[7px]': size === 'small',
      'rounded-l-none rounded-r-[9px]': size === 'medium' || size === undefined,
      'rounded-l-none rounded-r-[13px]': size === 'large',
    });
  }

  return cx({
    'rounded-[7px]': size === 'small',
    'rounded-[9px]': size === 'medium' || size === undefined,
    'rounded-[13px]': size === 'large',
  });
};

const getSizeClasses = (
  size: ButtonSize | undefined,
  hasLabel: boolean,
  splitPart?: 'main' | 'dropdown',
): string => {
  return cx(
    hasLabel
      ? {
          'px-2 py-1 text-[13px]': size === 'small',
          'px-2.5 py-1.5 text-[15px]': size === 'medium' || size === undefined,
          'px-3.5 py-2.75 text-base': size === 'large',
        }
      : {
          'px-1.5 py-1 text-[13px]': size === 'small' && splitPart === 'dropdown',
          'px-1 py-1 text-[13px]': size === 'small' && splitPart !== 'dropdown',
          'px-1.5 py-1.5 text-[15px]': size === 'medium' || size === undefined,
          'px-2.75 py-2.75 text-base': size === 'large',
        },
    getRoundedClasses(size, splitPart),
  );
};

const Button = React.forwardRef<HTMLElement, Props>((props, ref) => {
  const passThroughProps = getPassThroughProps(props);
  const isDisabled = props.disabled || props.loading;
  const iconPosition = props.iconPosition ?? 'left';
  const hasLabel =
    props.children !== undefined && props.children !== null && props.children !== '';
  const hasDropdown = props.dropdownItems !== undefined && props.dropdownItems.length > 0;
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

  const getButtonClasses = (
    contentHasLabel: boolean,
    splitPart?: 'main' | 'dropdown',
  ): string =>
    cx(
      'relative inline-flex items-center justify-center border font-[450] shadow outline-none transition-[background-color,border-color,box-shadow,opacity] duration-150 focus-visible:z-10 focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-offset-stone-50 select-none',
      isDisabled ? 'cursor-not-allowed opacity-50' : 'cursor-pointer',
      {
        'border-violet-800 bg-violet-500 text-white shadow-violet-500/30 focus-visible:ring-violet-400/70':
          props.variant === 'primary',
        'border-stone-300/80 bg-white text-stone-800 shadow-stone-300/30 focus-visible:ring-stone-400/70':
          props.variant === 'default' || props.variant === undefined,
        'border-transparent bg-transparent text-stone-600 shadow-transparent focus-visible:ring-stone-400/70':
          props.variant === 'ghost',
        'border-[#E9C8C7] bg-red-600/3 text-red-900/80 shadow-red-700/10 focus-visible:ring-red-400/70':
          props.variant === 'destructive',
      },
      !isDisabled && {
        'hover:z-10 hover:border-violet-900 hover:shadow-violet-500/50':
          props.variant === 'primary',
        'hover:z-10 hover:border-stone-400/70 hover:shadow-stone-300/80':
          props.variant === 'default' || props.variant === undefined,
        'hover:bg-stone-200/70': props.variant === 'ghost',
        'hover:z-10 hover:border-red-600/35 hover:shadow-red-700/20':
          props.variant === 'destructive',
      },
      getSizeClasses(props.size, contentHasLabel, splitPart),
      splitPart === undefined && props.className,
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

  const mainButtonClasses = getButtonClasses(hasLabel, hasDropdown ? 'main' : undefined);

  const renderMainAction = (): React.ReactNode => {
    switch (props.type) {
      case 'button':
        return (
          <button
            {...passThroughProps}
            ref={ref as React.Ref<HTMLButtonElement>}
            type="button"
            className={mainButtonClasses}
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
            className={mainButtonClasses}
            type="submit"
            disabled={isDisabled}
            aria-label={props.ariaLabel}
            aria-busy={props.loading ? true : undefined}
          >
            {content}
          </button>
        );
      case 'link': {
        const isInternalLink = props.href.startsWith('/') && !props.href.startsWith('//');

        return isInternalLink ? (
          <Link
            to={props.href}
            className={mainButtonClasses}
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
          </Link>
        ) : (
          <a
            {...passThroughProps}
            ref={ref as React.Ref<HTMLAnchorElement>}
            className={mainButtonClasses}
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
    }
  };

  if (!hasDropdown) {
    return renderMainAction();
  }

  return (
    <span className={cx('inline-flex items-stretch', props.className)}>
      {renderMainAction()}
      <DropdownMenu
        disabled={isDisabled}
        searchable={props.dropdownSearchable}
        trigger={
          <button
            type="button"
            className={cx(getButtonClasses(false, 'dropdown'), 'group')}
            disabled={isDisabled}
            aria-label={props.dropdownAriaLabel ?? 'More actions'}
            aria-busy={props.loading ? true : undefined}
          >
            <ChevronDownIcon
              className={cx(
                iconClasses,
                'transition-transform duration-150 group-hover:translate-y-0.5',
              )}
              aria-hidden="true"
            />
          </button>
        }
      >
        {props.dropdownItems?.map((item, index) => (
          <DropdownMenuItem
            key={`${item.title}-${index}`}
            title={item.title}
            icon={item.icon}
            selected={item.selected}
            onSelect={item.onSelect}
          >
            {item.children}
          </DropdownMenuItem>
        ))}
      </DropdownMenu>
    </span>
  );
});

Button.displayName = 'Button';

export default Button;
