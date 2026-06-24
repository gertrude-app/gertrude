import cx from 'classnames';
import Link from 'next/link';
import React from 'react';

type ButtonSize = `lg` | `sm` | `xs`;
type ButtonColor = `primary` | `secondary` | `success`;
type ButtonIcon = React.ComponentType<{ className?: string; size?: number }>;

interface CommonProps {
  children: React.ReactNode;
  size?: ButtonSize;
  color?: ButtonColor;
  Icon?: ButtonIcon;
  iconPosition?: `left` | `right`;
  inverted?: boolean;
  className?: string;
  id?: string;
  disabled?: boolean;
  variant?: `default` | `flat`;
}

interface LinkProps {
  type: `link`;
  href: string;
  target?: string;
  rel?: string;
}

interface SubmitProps {
  type: `submit`;
}

interface ActionProps {
  type: `button`;
  onClick(): unknown;
}

type ButtonProps = (LinkProps | SubmitProps | ActionProps) & CommonProps;

const Button: React.FC<ButtonProps> = (props) => {
  const size = props.size ?? `sm`;
  const color = props.color ?? `secondary`;
  const iconPosition = props.iconPosition ?? `left`;
  const variant = props.variant ?? `default`;
  const Icon = props.Icon;
  const iconSize = size === `lg` ? 24 : size === `sm` ? 20 : 16;
  const iconClasses = cx(
    `relative shrink-0`,
    size === `lg` && `size-6`,
    size === `sm` && `size-5`,
    size === `xs` && `size-4`,
  );
  const classes = cx(
    `group relative inline-flex select-none items-center justify-center overflow-hidden font-semibold transition-[transform,background-color,border-color,box-shadow] duration-200 focus:outline-none focus-visible:ring-2 focus-visible:ring-fuchsia-300`,
    props.disabled && `pointer-events-none opacity-50`,
    size === `lg` && `gap-3 rounded-2xl px-8 py-4 text-xl leading-6`,
    size === `sm` && `gap-2 rounded-xl px-6 py-3 text-base leading-6`,
    size === `xs` && `gap-1.5 rounded-lg px-4 py-2 text-sm leading-5`,
    color === `primary` &&
      (props.inverted
        ? `bg-white text-violet-700 shadow-lg shadow-black/10 hover:bg-violet-50 active:bg-violet-100`
        : `bg-gradient-to-r from-violet-500 to-fuchsia-500 text-white shadow-lg shadow-fuchsia-500/25 hover:shadow-fuchsia-500/35`),
    color === `secondary` &&
      (props.inverted
        ? `bg-white/10 text-white hover:bg-white/15 active:bg-white/20`
        : `bg-violet-100 text-violet-700 hover:bg-violet-200 active:bg-violet-300`),
    color === `success` && `bg-green-500 text-white shadow-lg shadow-green-500/20`,
    !props.disabled &&
      variant === `default` &&
      `hover:-translate-y-0.5 active:translate-y-0`,
    !props.disabled && variant === `flat` && `active:scale-[0.98]`,
    props.className,
  );

  const content = (
    <>
      {color === `primary` && !props.disabled && (
        <span
          className={cx(
            `absolute -left-20 top-1/2 h-24 w-16 -translate-y-1/2 rotate-12 bg-gradient-to-r from-transparent to-transparent opacity-0 transition-[left,opacity] duration-300 group-hover:left-full group-hover:opacity-100 group-active:opacity-0`,
            props.inverted ? `via-violet-100/80` : `via-white/20`,
          )}
        />
      )}
      {Icon && iconPosition === `left` && (
        <Icon className={iconClasses} size={iconSize} />
      )}
      <span className="relative text-center">{props.children}</span>
      {Icon && iconPosition === `right` && (
        <Icon
          className={cx(iconClasses, `transition-transform group-hover:translate-x-0.5`)}
          size={iconSize}
        />
      )}
    </>
  );

  switch (props.type) {
    case `link`:
      return (
        <Link
          id={props.id}
          href={props.href}
          target={props.target}
          rel={props.rel}
          className={classes}
          aria-disabled={props.disabled}
          tabIndex={props.disabled ? -1 : undefined}
        >
          {content}
        </Link>
      );
    case `submit`:
      return (
        <button id={props.id} type="submit" className={classes} disabled={props.disabled}>
          {content}
        </button>
      );
    case `button`:
      return (
        <button
          id={props.id}
          type="button"
          onClick={props.onClick}
          className={classes}
          disabled={props.disabled}
        >
          {content}
        </button>
      );
  }
};

export default Button;
