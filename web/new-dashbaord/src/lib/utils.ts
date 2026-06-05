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

export const daysOfWeek = [
  `Sunday`,
  `Monday`,
  `Tuesday`,
  `Wednesday`,
  `Thursday`,
  `Friday`,
  `Saturday`,
] as const;

export function getDayOfWeek(date: Date): (typeof daysOfWeek)[number] {
  return daysOfWeek[date.getDay()];
}

export const monthsOfYear = [
  `January`,
  `February`,
  `March`,
  `April`,
  `May`,
  `June`,
  `July`,
  `August`,
  `September`,
  `October`,
  `November`,
  `December`,
] as const;

export function getMonthOfYear(date: Date): (typeof monthsOfYear)[number] {
  return monthsOfYear[date.getMonth()];
}

export function formatDate(date: Date): string {
  return `${getDayOfWeek(date)}, ${getMonthOfYear(date)} ${date.getDate()}`;
}
