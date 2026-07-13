import type { AllowedAlbum, Device, Schedule, TimeOfDay } from './types';

const deviceImageBaseUrls = {
  mac: `/devices/macs`,
  iphone: `/devices/iphones`,
  ipad: `/devices/ipads`,
};

export const deviceImageUrl = (
  deviceType: keyof typeof deviceImageBaseUrls,
  modelIdentifier: string,
): string => `${deviceImageBaseUrls[deviceType]}/${modelIdentifier}.png`;

export const deviceTitle = (device: Device): string =>
  device.type === `mac` ? (device.name ?? device.modelName) : device.modelName;

export const deviceSubtitle = (device: Device): string => {
  if (device.type === `mac`) {
    return `${device.name ? `${device.modelName} • ` : ``}macOS ${device.macOSVersion}`;
  }

  return `${device.type === `iphone` ? `iOS` : `iPadOS`} ${device.iOSVersion}`;
};

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

type DayKey = keyof Schedule[`days`];

export const dayEntries = scheduleDayEntries as ReadonlyArray<readonly [DayKey, string]>;

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

export const timeOfDayToInputValue = (time: TimeOfDay): string =>
  `${`${time.hour}`.padStart(2, `0`)}:${`${time.minute}`.padStart(2, `0`)}`;

export const inputValueToTimeOfDay = (value: string): TimeOfDay | null => {
  const [hourString, minuteString] = value.split(`:`);

  if (hourString === undefined || minuteString === undefined) {
    return null;
  }

  const hour = Number(hourString);
  const minute = Number(minuteString);

  if (
    !Number.isInteger(hour) ||
    !Number.isInteger(minute) ||
    hour < 0 ||
    hour > 23 ||
    minute < 0 ||
    minute > 59
  ) {
    return null;
  }

  return { hour, minute };
};

export const albumKey = (album: AllowedAlbum): string =>
  `${album.title}::${album.artist}`;
