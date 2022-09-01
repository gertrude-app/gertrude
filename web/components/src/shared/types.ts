import type { JSXElementConstructor, ComponentProps } from 'react';

export type Subcomponents<
  T extends keyof JSX.IntrinsicElements | JSXElementConstructor<any>,
> = Array<ComponentProps<T> & { id: string }>;

export type SubcomponentsOmit<
  T extends keyof JSX.IntrinsicElements | JSXElementConstructor<any>,
  K extends keyof ComponentProps<T>,
> = Array<Omit<ComponentProps<T> & { id: string }, K>>;

export interface ConfirmableEntityAction {
  id?: UUID;
  start(id: UUID): unknown;
  confirm(): unknown;
  cancel(): unknown;
}
