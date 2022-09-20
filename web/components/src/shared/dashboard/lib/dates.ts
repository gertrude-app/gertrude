// import * as typesafe from './typesafe';
/**
 * long: `Thursday, August 18, 2022`
 * medium: `Thursday, Aug. 18, 2022`
 * short: `8/18/22`
 * url: `08-18-2022`
 */
export function formatDate(
  date: Date,
  style: 'long' | 'medium' | 'short' | 'url',
): string {
  if (style === `short`) {
    return date.toLocaleDateString();
  }

  if (style === `url`) {
    return [
      `${date.getMonth() + 1}`.padStart(2, `0`),
      `${date.getDate()}`.padStart(2, `0`),
      `${date.getFullYear()}`,
    ].join(`-`);
  }

  return [
    date.toLocaleDateString(`en-US`, { weekday: `long` }),
    `, `,
    date.toLocaleDateString(`en-US`, { month: style === `long` ? `long` : `short` }),
    style === `long` ? ` ` : `. `,
    date.getDate(),
    `, `,
    date.getFullYear(),
  ].join(``);
}
type Entries<T> = {
  [K in keyof T]: [K, T[K]];
}[keyof T][];

export function objectEntries<T extends Record<string, unknown>>(obj: T): Entries<T> {
  return Object.entries(obj) as any;
}

const rtf = new Intl.RelativeTimeFormat(`en`, { numeric: `auto` });

export function relativeTime(date: Date): string {
  const now = new Date();
  const diff = now.getTime() - date.getTime();
  const UNITS = {
    year: 24 * 60 * 60 * 1000 * 365,
    month: (24 * 60 * 60 * 1000 * 365) / 12,
    day: 24 * 60 * 60 * 1000,
    hour: 60 * 60 * 1000,
    minute: 60 * 1000,
    second: 1000,
  } as const;
  for (const [unit, num] of Object.entries(UNITS)) {
    if (Math.abs(diff) > num || unit === `second`) {
      return rtf.format(-Math.round(diff / num), unit as any);
    }
  }
  return `now`;
}

export function dateFromUrl(urlDate: string): Date {
  const [month, days, year] = urlDate.split(`-`);
  return new Date(Date.parse(`${year}-${month}-${days}T12:00:00.000Z`));
}

export function formatDateAndTimeFromInputElements(date: string, time: string): string {
  const expiry = new Date(date);
  expiry.setHours(Number(time.split(`:`)[0]));
  expiry.setMinutes(Number(time.split(`:`)[1]));
  return `${formatDate(expiry, `medium`)} at ${expiry.toLocaleTimeString(`en-US`)}`;
}
