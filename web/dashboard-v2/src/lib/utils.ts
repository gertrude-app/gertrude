import type { Schedule, TimeOfDay } from './mock';

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

export function formatTime(timeOfDay: TimeOfDay): string {
  const amPm = timeOfDay.hour >= 12 ? `PM` : `AM`;
  const hour = timeOfDay.hour % 12 || 12;
  return `${hour}:${`${timeOfDay.minute}`.padStart(2, `0`)} ${amPm}`;
}

const scheduleDayEntries = [
  [`sunday`, `Sun`],
  [`monday`, `Mon`],
  [`tuesday`, `Tue`],
  [`wednesday`, `Wed`],
  [`thursday`, `Thu`],
  [`friday`, `Fri`],
  [`saturday`, `Sat`],
] as const;

const formatList = (items: string[]): string => {
  if (items.length <= 2) {
    return items.join(` and `);
  }

  return `${items.slice(0, -1).join(`, `)}, and ${items.at(-1)}`;
};

const formatScheduleDays = (days: Schedule[`days`]): string => {
  const selectedDays = scheduleDayEntries
    .filter(([key]) => days[key])
    .map(([, label]) => label);
  const selectedKeys = scheduleDayEntries
    .filter(([key]) => days[key])
    .map(([key]) => key);

  if (selectedDays.length === 7) {
    return `every day`;
  }

  if (selectedDays.length === 0) {
    return `no days`;
  }

  if (selectedKeys.join(`,`) === `monday,tuesday,wednesday,thursday,friday`) {
    return `weekdays`;
  }

  if (selectedKeys.join(`,`) === `sunday,saturday`) {
    return `weekends`;
  }

  return formatList(selectedDays);
};

export function formatSchedule(schedule: Schedule): string {
  const scheduleType = schedule.type === `active` ? `Active` : `Inactive`;
  const days = formatScheduleDays(schedule.days);
  const dayPrefix = days === `every day` ? days : `on ${days}`;

  return `${scheduleType} ${dayPrefix} from ${formatTime(schedule.startTime)} to ${formatTime(schedule.endTime)}`;
}
