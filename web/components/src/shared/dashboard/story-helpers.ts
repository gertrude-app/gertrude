import { ConfirmableEntityAction } from '../types';
import KeychainCard from './Users/KeychainCard';

export function keychainProps(
  override: Partial<React.ComponentProps<typeof KeychainCard> & { id: UUID }> = {},
): React.ComponentProps<typeof KeychainCard> & { id: UUID } {
  return {
    id: `id-${Math.random()}`,
    isPublic: false,
    name: `HTC`,
    description: `Lorem ipsum, dolor sit amet consectetur adipisicing elit. Tempore laudantium velit assumenda nemo exercitationem.`,
    numKeys: 232,
    onRemove: () => {},
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
