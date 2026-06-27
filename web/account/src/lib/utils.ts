export function groupBy<T, K>(items: readonly T[], key: (item: T) => K): Map<K, T[]> {
  const groups = new Map<K, T[]>();

  for (const item of items) {
    const groupKey = key(item);
    const group = groups.get(groupKey);

    if (group) {
      group.push(item);
    } else {
      groups.set(groupKey, [item]);
    }
  }

  return groups;
}
