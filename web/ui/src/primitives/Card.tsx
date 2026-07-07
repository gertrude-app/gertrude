import cx from 'clsx';
import React from 'react';
import type {
  PolymorphicComponent,
  PolymorphicProps,
  PolymorphicRef,
} from './polymorphic';
import type { VisibilityProps } from './visibility';
import {
  type ResponsiveSpacing,
  type Spacing,
  cardPaddingClasses,
  getResponsiveSpacingStyle,
} from './spacing';
import { getVisibilityClasses } from './visibility';

export type CardElement = React.ElementType;
export type CardPadding = ResponsiveSpacing;
export type CardPreset = `big` | `compact`;

export interface CardOwnProps extends VisibilityProps {
  children?: React.ReactNode;
  preset?: CardPreset;
  padding?: CardPadding;
  interactive?: boolean;
  selected?: boolean;
  disabled?: boolean;
  className?: string;
  style?: React.CSSProperties;
}

export type CardProps<Element extends React.ElementType = `div`> = PolymorphicProps<
  Element,
  CardOwnProps
>;

export interface CardBodyProps extends VisibilityProps {
  children?: React.ReactNode;
  padding?: CardPadding;
  className?: string;
  style?: React.CSSProperties;
}

export interface CardFooterProps extends VisibilityProps {
  children?: React.ReactNode;
  className?: string;
  style?: React.CSSProperties;
}

const cardPresetClasses: Record<CardPreset, string> = {
  big: `rounded-2xl shadow-md`,
  compact: `rounded-xl shadow`,
};

const cardPresetPadding: Record<CardPreset, Spacing> = {
  big: 4,
  compact: 3,
};

const disabledElementNames = new Set([
  `button`,
  `fieldset`,
  `input`,
  `option`,
  `select`,
  `textarea`,
]);

const getDisabledProps = (
  component: React.ElementType,
  disabled: boolean | undefined,
): Record<string, boolean> => {
  if (disabled === undefined) {
    return {};
  }

  if (typeof component !== `string` || disabledElementNames.has(component)) {
    return { disabled };
  }

  return disabled ? { 'aria-disabled': true } : {};
};

type CardBaseComponent = PolymorphicComponent<`div`, CardOwnProps>;

type CardComponent = CardBaseComponent & {
  Body: typeof CardBody;
  Footer: typeof CardFooter;
};

const CardRender = <Element extends React.ElementType = `div`>({
  as,
  preset = `compact`,
  padding,
  interactive,
  selected,
  disabled,
  className,
  children,
  style,
  hideBelow,
  hideAbove,
  ref,
  ...props
}: CardProps<Element> & { ref?: PolymorphicRef<Element> }): React.ReactElement => {
  const defaultPadding = cardPresetPadding[preset];
  const Component = as ?? `div`;

  return React.createElement(
    Component,
    {
      ...props,
      ...getDisabledProps(Component, disabled),
      ref,
      style: {
        ...getResponsiveSpacingStyle(
          padding ?? defaultPadding,
          `card-padding`,
          defaultPadding,
        ),
        ...style,
      },
      className: cx(
        `border`,
        cardPresetClasses[preset],
        cardPaddingClasses,
        disabled
          ? `border-stone-200 bg-stone-100/70 opacity-60 shadow-transparent`
          : selected
            ? `border-violet-300 bg-violet-50 shadow-violet-300/30`
            : `border-stone-200 bg-white shadow-stone-300/30`,
        interactive &&
          `transition-[background-color,border-color,box-shadow,opacity] duration-150 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-violet-300/80`,
        interactive &&
          !disabled &&
          cx(
            `cursor-pointer`,
            selected
              ? `hover:border-violet-400 hover:shadow-violet-300/50`
              : `hover:border-stone-400/70 hover:shadow-stone-300/70`,
          ),
        disabled && `cursor-not-allowed`,
        getVisibilityClasses({ hideBelow, hideAbove, restoreDisplay: `block` }),
        className,
      ),
    },
    children,
  );
};

const CardBody: React.FC<CardBodyProps> = ({
  children,
  padding = 4,
  className,
  style,
  hideBelow,
  hideAbove,
}) => (
  <div
    style={{
      ...getResponsiveSpacingStyle(padding, `card-padding`, 4),
      ...style,
    }}
    className={cx(
      cardPaddingClasses,
      getVisibilityClasses({ hideBelow, hideAbove, restoreDisplay: `block` }),
      className,
    )}
  >
    {children}
  </div>
);

const CardFooter: React.FC<CardFooterProps> = ({
  children,
  className,
  style,
  hideBelow,
  hideAbove,
}) => (
  <div
    style={style}
    className={cx(
      `shrink-0 rounded-b-[inherit] border-t border-stone-200 bg-stone-50/80 px-3 py-2`,
      getVisibilityClasses({ hideBelow, hideAbove, restoreDisplay: `block` }),
      className,
    )}
  >
    {children}
  </div>
);

const Card = Object.assign(CardRender as CardBaseComponent, {
  Body: CardBody,
  Footer: CardFooter,
}) as CardComponent;

export default Card;
