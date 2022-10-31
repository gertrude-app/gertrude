import { formatDate, isoToDateInput } from '../../lib/dates';
export { formatDate, isoToDateInput };

export function isOlderThan(
  isoOrDate: string | Date,
  amounts: {
    days?: number;
    hours?: number;
    minutes?: number;
  },
): boolean {
  const date = typeof isoOrDate === `string` ? new Date(isoOrDate) : isoOrDate;
  const compare = new Date();
  if (amounts.days) {
    compare.setDate(compare.getDate() - amounts.days);
  }
  if (amounts.hours) {
    compare.setHours(compare.getHours() - amounts.hours);
  }
  if (amounts.minutes) {
    compare.setMinutes(compare.getMinutes() - amounts.minutes);
  }
  return date < compare;
}

export function isoToTimeInput(iso: string): string {
  const [, time = `12:00`] = iso.split(`T`);
  return time.slice(0, 5);
}

export function daysFromNow(days: number): Date {
  const date = new Date();
  date.setDate(date.getDate() + days);
  return date;
}

export function localToUtc(localDate: Date): Date {
  const tzOffsetMs = new Date().getTimezoneOffset() * 60000;
  const withoutOffset = new Date(localDate.getTime());
  const withOffset = new Date(withoutOffset.getTime() + tzOffsetMs);
  return withOffset;
}

export function localIsoToUtc(localTime: string): string {
  const tzOffsetMs = new Date().getTimezoneOffset() * 60000;
  const withoutOffset = new Date(localTime);
  const withOffset = new Date(withoutOffset.getTime() + tzOffsetMs);
  return withOffset.toISOString();
}

export function utcToLocal(utc: Date): Date {
  const tzOffsetMs = new Date().getTimezoneOffset() * 60000;
  const withoutOffset = new Date(utc.getTime());
  const withOffset = new Date(withoutOffset.getTime() - tzOffsetMs);
  return withOffset;
}

export function isoToLocal(iso: string): string {
  const tzOffsetMs = new Date().getTimezoneOffset() * 60000;
  const withoutOffset = new Date(iso);
  const withOffset = new Date(withoutOffset.getTime() - tzOffsetMs);
  return withOffset.toISOString();
}

export function isoFromDateInput(dateInput: string, existingIso?: string): string {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(dateInput)) {
    throw new Error(`Invalid date input: ${dateInput}`);
  }

  const date = new Date(existingIso ?? Date.now());
  date.setDate(1); // Reset to first day of month, avoid overflow
  const [year = 0, month = 0, day = 0] = dateInput.split(`-`).map((s) => parseInt(s, 10));
  date.setFullYear(year);
  date.setMonth(month - 1);
  date.setDate(day);
  return date.toISOString();
}

const rtf = new Intl.RelativeTimeFormat(`en`, { numeric: `auto` });

export function relativeTime(isoOrDate: Date | string): string {
  const date = typeof isoOrDate === `string` ? new Date(isoOrDate) : isoOrDate;
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
  return `just now`;
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

export function timeOfDay(date: Date): 'morning' | 'afternoon' | 'evening' {
  const time = date.getHours();
  if (time < 12) return `morning`;
  else if (time < 17) return `afternoon`;
  return `evening`;
}
