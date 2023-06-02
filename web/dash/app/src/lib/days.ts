import type { DateRangeInput } from '@dash/types';

export function entireDay(date: Date): DateRangeInput {
  const start = new Date(date.getTime());
  mutateToDayBegin(start);
  const end = new Date(date.getTime());
  mutateToDayEnd(end);
  return {
    start: start.toISOString(),
    end: end.toISOString(),
  };
}

export function entireDays(numDays: number): DateRangeInput[] {
  const now = new Date();
  const ranges: DateRangeInput[] = [];
  for (let i = 0; i < numDays; i++) {
    const day = new Date(now.getTime());
    day.setDate(now.getDate() - i);
    ranges.push(entireDay(day));
  }
  return ranges;
}

function mutateToDayEnd(date: Date): void {
  date.setHours(23);
  date.setMinutes(59);
  date.setSeconds(59);
  date.setMilliseconds(999);
}

function mutateToDayBegin(date: Date): void {
  date.setHours(0);
  date.setMinutes(0);
  date.setSeconds(0);
  date.setMilliseconds(0);
}
