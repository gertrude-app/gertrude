import KeychainCard from './Users/KeychainCard';

export function keychainProps(
  override: Partial<React.ComponentProps<typeof KeychainCard> & { id: UUID }> = {},
): React.ComponentProps<typeof KeychainCard> & { id: UUID } {
  return {
    id: `id-${Math.random()}`,
    isPublic: false,
    name: `HTC`,
    description: `Lorem ipsum, dolor sit amet consectetur adipisicing elit. Tempore laudantium velit assumenda nemo exercitationem.`,
    keys: 232,
    onRemove: () => {},
    ...override,
  };
}
