import type { ResponsiveSpacing, Spacing } from './spacing';
import type React from 'react';

export type StackGap = Spacing;
export type ResponsiveStackGap = ResponsiveSpacing;
export type StackAlign = `start` | `center` | `end` | `stretch` | `baseline`;
export type StackJustify = `start` | `center` | `end` | `between` | `around` | `evenly`;
export type StackElement =
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

export interface StackProps extends React.HTMLAttributes<HTMLElement> {
  children?: React.ReactNode;
  as?: StackElement;
  gap?: ResponsiveStackGap;
  align?: StackAlign;
  justify?: StackJustify;
  className?: string;
}

export const stackAlignClasses: Record<StackAlign, string> = {
  start: `items-start`,
  center: `items-center`,
  end: `items-end`,
  stretch: `items-stretch`,
  baseline: `items-baseline`,
};

export const stackJustifyClasses: Record<StackJustify, string> = {
  start: `justify-start`,
  center: `justify-center`,
  end: `justify-end`,
  between: `justify-between`,
  around: `justify-around`,
  evenly: `justify-evenly`,
};
