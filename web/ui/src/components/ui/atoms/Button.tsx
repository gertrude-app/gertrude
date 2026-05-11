import React from 'react';
import { LoaderCircleIcon, type LucideIcon } from 'lucide-react';
import cx from 'clsx';

// testing

type Props = {
  children: React.ReactNode;
  icon?: LucideIcon;
  iconPosition?: 'left' | 'right'; // defaults to 'left'
  variant?: 'primary' | 'default' | 'ghost' | 'destructive'; // defaults to 'default'
  size?: 'small' | 'medium' | 'large'; // defaults to 'medium'
  loading?: boolean;
} & (
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
  const innerClasses = cx(
    'font-[450] flex items-center',
    {
      'bg-violet-500 text-white': props.variant === 'primary',
      'bg-white text-stone-800':
        props.variant === 'default' || props.variant === undefined,
      'bg-none text-stone-600': props.variant === 'ghost',
      'bg-white/70 text-red-900/80': props.variant === 'destructive',
    },
    {
      'px-1.5 py-0.5 rounded-md text-xs gap-1.25': props.size === 'small',
      'px-2 py-1 rounded-lg text-sm gap-1.5':
        props.size === 'medium' || props.size === undefined,
      'px-3 py-2 rounded-xl gap-2': props.size === 'large',
    },
  );
  const outerClasses = cx(
    'p-[1px] cursor-pointer outline-none transition-[background-color,box-shadow] duration-100 focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-offset-stone-50',
    props.loading && 'opacity-50 pointer-events-none',
    {
      'bg-violet-800 shadow-violet-500/30 hover:shadow-violet-500/50 hover:bg-violet-900 focus-visible:ring-violet-400/70':
        props.variant === 'primary',
      'bg-stone-300/80 shadow-stone-300/30 hover:bg-stone-400/70 hover:shadow-stone-300/80 focus-visible:ring-stone-400/70':
        props.variant === 'default' || props.variant === undefined,
      'bg-none hover:bg-stone-200/70 shadow-transparent focus-visible:ring-stone-400/70':
        props.variant === 'ghost',
      'bg-red-600/30 hover:bg-red-600/50 shadow-red-700/10 focus-visible:ring-red-400/70':
        props.variant === 'destructive',
    },
    {
      'rounded-[7px] shadow': props.size === 'small',
      'rounded-[9px] shadow': props.size === 'medium' || props.size === undefined,
      'rounded-[13px] shadow': props.size === 'large',
    },
  );
  const iconClasses = cx({
    'w-3 h-3': props.size === 'small',
    'w-4 h-4': props.size === 'medium' || props.size === undefined,
    'w-5 h-5': props.size === 'large',
  });

  let Icon = props.icon;

  switch (props.type) {
    case 'button':
      return (
        <button className={outerClasses} onClick={props.onClick}>
          <div className={innerClasses}>
            {props.loading && (
              <LoaderCircleIcon className={cx(iconClasses, 'animate-spin')} />
            )}
            {(props.iconPosition === 'left' || !props.iconPosition) && Icon && (
              <Icon className={iconClasses} />
            )}
            <span>{props.children}</span>
            {props.iconPosition === 'right' && Icon && <Icon className={iconClasses} />}
          </div>
        </button>
      );
    case 'submit':
      return (
        <button className={outerClasses} type="submit">
          <div className={innerClasses}>{props.children}</div>
        </button>
      );
    case 'link':
      return (
        <a className={outerClasses} href={props.href}>
          <div className={innerClasses}>{props.children}</div>
        </a>
      );
  }
};

export default Button;
