import cx from 'clsx';
import React from 'react';
import type {
  PolymorphicComponent,
  PolymorphicProps,
  PolymorphicRef,
} from './polymorphic';
import type { VisibilityProps } from './visibility';
import { getVisibilityClasses } from './visibility';

export type TextVariant =
  | `display`
  | `title`
  | `heading`
  | `subheading`
  | `bodyLargeStrong`
  | `bodyLarge`
  | `bodyStrong`
  | `body`
  | `bodySubtle`
  | `prose`
  | `proseSubtle`
  | `bodyMuted`
  | `label`
  | `captionStrong`
  | `captionSubtleStrong`
  | `caption`
  | `captionSubtle`
  | `captionMuted`
  | `warning`
  | `error`
  | `code`;

export type TextLineClamp = 1 | 2 | 3 | 4;

export interface TextOwnProps extends VisibilityProps {
  children?: React.ReactNode;
  variant?: TextVariant;
  truncate?: boolean;
  lineClamp?: TextLineClamp;
  className?: string;
  style?: React.CSSProperties;
}

export type TextProps<Element extends React.ElementType = `span`> = PolymorphicProps<
  Element,
  TextOwnProps
>;

export const textVariantClasses: Record<TextVariant, string> = {
  display: `text-3xl font-medium text-stone-900`,
  title: `text-xl font-medium text-stone-950`,
  heading: `text-lg font-medium text-stone-900`,
  subheading: `text-lg text-stone-600`,
  bodyLargeStrong: `text-base font-medium text-stone-900`,
  bodyLarge: `text-base text-stone-900`,
  bodyStrong: `text-sm font-medium text-stone-900`,
  body: `text-sm text-stone-700`,
  bodySubtle: `text-sm text-stone-600`,
  prose: `text-sm leading-6 text-stone-700`,
  proseSubtle: `text-sm leading-6 text-stone-600`,
  bodyMuted: `text-sm text-stone-500`,
  label: `text-[13px] font-medium text-stone-500`,
  captionStrong: `text-xs font-medium text-stone-900`,
  captionSubtleStrong: `text-xs font-medium text-stone-600`,
  caption: `text-xs text-stone-700`,
  captionSubtle: `text-xs text-stone-600`,
  captionMuted: `text-xs text-stone-500`,
  warning: `text-sm text-amber-800`,
  error: `text-[13px] leading-5 text-red-500`,
  code: `font-mono text-sm text-stone-800`,
};

const lineClampClasses: Record<TextLineClamp, string> = {
  1: `line-clamp-1`,
  2: `line-clamp-2`,
  3: `line-clamp-3`,
  4: `line-clamp-4`,
};

type TextComponent = PolymorphicComponent<`span`, TextOwnProps>;

const TextRender = <Element extends React.ElementType = `span`>({
  as,
  variant = `body`,
  truncate,
  lineClamp,
  className,
  children,
  hideBelow,
  hideAbove,
  ref,
  ...props
}: TextProps<Element> & { ref?: PolymorphicRef<Element> }): React.ReactElement => {
  const Component = as ?? `span`;

  return React.createElement(
    Component,
    {
      ...props,
      ref,
      className: cx(
        textVariantClasses[variant],
        truncate && `truncate`,
        lineClamp && lineClampClasses[lineClamp],
        getVisibilityClasses({ hideBelow, hideAbove, restoreDisplay: `inline` }),
        className,
      ),
    },
    children,
  );
};

const Text = TextRender as TextComponent;

export default Text;
