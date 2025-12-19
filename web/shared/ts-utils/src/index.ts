export * as typesafe from './typesafe';
export * from './typesafe';

export function notNullish<T>(x: T | null | undefined): x is T {
  return x !== null && x !== undefined;
}

export type ReadOnly<T> = { readonly [K in keyof T]: ReadOnly<T[K]> };
