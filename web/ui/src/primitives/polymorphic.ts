import type React from 'react';

export type PolymorphicElement = React.ElementType;

export type PolymorphicRef<Element extends PolymorphicElement> =
  React.ComponentPropsWithRef<Element>[`ref`];

type RequireDestinationProp<Props> = Props extends { to?: infer To }
  ? Omit<Props, `to`> & { to: NonNullable<To> }
  : Props;

export type PolymorphicProps<Element extends PolymorphicElement, Props = object> = Props &
  Omit<
    RequireDestinationProp<React.ComponentPropsWithoutRef<Element>>,
    keyof Props | `as`
  > & {
    as?: Element;
  };

export type PolymorphicComponent<
  DefaultElement extends PolymorphicElement,
  Props = object,
> = <Element extends PolymorphicElement = DefaultElement>(
  props: PolymorphicProps<Element, Props> & { ref?: PolymorphicRef<Element> },
) => React.ReactElement | null;
