export function isoToDateInput(iso: string): string {
  return formatDate(new Date(iso), `dateInput`);
}

export function formatDate(
  date: Date,
  style: 'long' | 'medium' | 'short' | 'url' | 'dateInput',
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

  if (style === `dateInput`) {
    return [
      `${date.getFullYear()}`,
      `${date.getMonth() + 1}`.padStart(2, `0`),
      `${date.getDate()}`.padStart(2, `0`),
    ].join(`-`);
  }

  return [
    date.toLocaleDateString(`en-US`, { weekday: `long` }),
    `, `,
    date.toLocaleDateString(`en-US`, { month: style === `long` ? `long` : `short` }),
    ` `,
    date.getDate(),
    `, `,
    date.getFullYear(),
  ].join(``);
}

export const time = {
  now,
  subtracting,
  adding,
  stable,
};

function stable(): string {
  return `2022-01-01T12:00:00.000Z`;
}

function adding(amounts: { days?: number; hours?: number; minutes?: number }): string {
  const date = new Date();
  if (amounts.days) {
    date.setDate(date.getDate() + amounts.days);
  }
  if (amounts.hours) {
    date.setHours(date.getHours() + amounts.hours);
  }
  if (amounts.minutes) {
    date.setMinutes(date.getMinutes() + amounts.minutes);
  }
  return date.toISOString();
}

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
