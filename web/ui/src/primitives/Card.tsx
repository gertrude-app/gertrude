import cx from 'clsx';
import React from 'react';
import {
  type ResponsiveSpacing,
  cardPaddingClasses,
  getResponsiveSpacingStyle,
} from './spacing';

export type CardElement =
  | `div`
  | `section`
  | `article`
  | `main`
  | `nav`
  | `header`
  | `footer`
  | `form`
  | `fieldset`
  | `ul`
  | `ol`
  | `li`;
export type CardPadding = ResponsiveSpacing;

export interface CardProps extends React.HTMLAttributes<HTMLElement> {
  children?: React.ReactNode;
  as?: CardElement;
  padding?: CardPadding;
  className?: string;
}

const Card: React.FC<CardProps> = ({
  as: Component = `div`,
  padding = 4,
  className,
  children,
  style,
  ...props
}) => (
  <Component
    {...props}
    style={{ ...getResponsiveSpacingStyle(padding, `card-padding`, 4), ...style }}
    className={cx(
      `rounded-2xl border border-stone-200 bg-white shadow-md shadow-stone-300/30`,
      cardPaddingClasses,
      className,
    )}
  >
    {children}
  </Component>
);

export default Card;
