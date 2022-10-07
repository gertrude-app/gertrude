import { ConfirmableEntityAction } from '../types';

export function keychainProps(override: Partial<Keychain> = {}): Keychain {
  return {
    id: `id-${Math.random()}`,
    isPublic: false,
    name: `HTC`,
    description: `Lorem ipsum, dolor sit amet consectetur adipisicing elit. Tempore laudantium velit assumenda nemo exercitationem.`,
    numKeys: 232,
    authorId: `authorId-${Math.random()}`,
    ...override,
  };
}

export function withIds<T extends Record<string, unknown>>(
  items: T[],
): Array<T & { id: UUID }> {
  return items.map((item, index) => ({ ...item, id: `${index + 1}` }));
}

export function withIdsAnd<
  T extends Record<string, unknown>,
  K extends Record<string, unknown>,
>(add: K, items: T[]): Array<T & K & { id: UUID }> {
  return adding(add, withIds(items));
}

export function adding<
  T extends Record<string, unknown>,
  K extends Record<string, unknown>,
>(add: K, items: T[]): Array<T & K> {
  return items.map((item) => ({ ...add, ...item }));
}

export function confirmableEntityAction<
  StartArg = UUID,
>(): ConfirmableEntityAction<StartArg> {
  return {
    start: () => {},
    confirm: () => {},
    cancel: () => {},
  };
}

export const time = {
  now,
  subtracting,
};

function subtracting(amounts: {
  days?: number;
  hours?: number;
  minutes?: number;
}): string {
  const date = new Date();
  if (amounts.days) {
    date.setDate(date.getDate() - amounts.days);
  }
  if (amounts.hours) {
    date.setHours(date.getHours() - amounts.hours);
  }
  if (amounts.minutes) {
    date.setMinutes(date.getMinutes() - amounts.minutes);
  }
  return date.toISOString();
}

function now(): string {
  return new Date().toISOString();
}
